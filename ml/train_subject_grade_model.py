import os
import json
import pickle
import warnings
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sklearn.base import clone
from sklearn.dummy import DummyClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import LeaveOneOut, cross_val_predict
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import StandardScaler
from sklearn.utils.class_weight import compute_sample_weight

UTC = timezone.utc
DB_URL = os.getenv(
    "DB_URL",
    "postgresql+psycopg2://Michael:Mickyb26*@192.168.8.8/marks-manager-db",
)
COURSE_ID = int(os.getenv("COURSE_ID", "1"))
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "big-data-stack/model_artifacts")
MODEL_BACKEND = os.getenv("MODEL_BACKEND", "sklearn-logreg").strip().lower()


def get_grade(mark):
    if mark >= 85:
        return "HD"
    if mark >= 75:
        return "D"
    if mark >= 65:
        return "C"
    if mark >= 50:
        return "P"
    return "F"


def load_subject_dataset(engine, course_id):
    query = """
    SELECT
        s.id AS subject_id,
        s.subject_name,
        s.total_mark AS actual_mark,
        COUNT(a.id) AS assessments_count,
        SUM(CASE WHEN a.unweighted_mark IS NULL THEN 1 ELSE 0 END) AS missing_score_count,
        AVG(a.unweighted_mark) AS avg_unweighted_mark,
        STDDEV_POP(a.unweighted_mark) AS std_unweighted_mark,
        MIN(a.unweighted_mark) AS min_unweighted_mark,
        MAX(a.unweighted_mark) AS max_unweighted_mark,
        SUM(a.mark_weight) AS total_weight,
        SUM(a.weighted_mark) AS total_weighted_mark,
        (SUM(a.weighted_mark) / NULLIF(SUM(a.mark_weight), 0)) * 100 AS potential_mark
    FROM courses c
    JOIN semesters sem ON c.id = sem.course_id
    JOIN subjects s ON sem.id = s.semester_id
    JOIN assignments a ON s.id = a.subject_id
    WHERE c.id = :course_id
    GROUP BY s.id, s.subject_name, s.total_mark
    HAVING
        s.total_mark IS NOT NULL
        AND COUNT(a.id) > 0
        AND SUM(a.mark_weight) > 0
    ORDER BY s.subject_name;
    """

    df = pd.read_sql_query(text(query), engine, params={"course_id": course_id})

    numeric_cols = [
        "actual_mark",
        "assessments_count",
        "missing_score_count",
        "avg_unweighted_mark",
        "std_unweighted_mark",
        "min_unweighted_mark",
        "max_unweighted_mark",
        "total_weight",
        "total_weighted_mark",
        "potential_mark",
    ]

    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    # Std dev can be NaN when a subject has only one scored assessment.
    df["std_unweighted_mark"] = df["std_unweighted_mark"].fillna(0)
    df["actual_grade"] = df["actual_mark"].apply(get_grade)

    return df


def build_model(backend):
    if backend == "xgboost-gpu":
        try:
            from xgboost import XGBClassifier
        except ImportError as exc:
            raise RuntimeError(
                "MODEL_BACKEND=xgboost-gpu was requested but xgboost is not installed. "
                "Install it with: pip install xgboost"
            ) from exc

        # GPU-accelerated gradient boosting classifier for desktop CUDA runs.
        return XGBClassifier(
            objective="multi:softprob",
            eval_metric="mlogloss",
            tree_method="hist",
            device="cuda",
            n_estimators=120,
            max_depth=4,
            learning_rate=0.08,
            subsample=0.9,
            colsample_bytree=0.9,
            random_state=42,
        )

    if backend != "sklearn-logreg":
        print(
            f"Unknown MODEL_BACKEND='{backend}'. Falling back to sklearn-logreg."
        )

    return Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "clf",
                LogisticRegression(
                    max_iter=1000,
                    class_weight="balanced",
                    random_state=42,
                ),
            ),
        ]
    )


def loo_predict(model, X, y, use_balanced_weights=False, force_cpu_predict=False):
    """Run Leave-One-Out manually so we can pass sample weights when needed."""
    cv = LeaveOneOut()
    y_pred = pd.Series(index=X.index, dtype=object)

    for train_idx, test_idx in cv.split(X):
        estimator = clone(model)
        X_train = X.iloc[train_idx]
        X_test = X.iloc[test_idx]
        y_train = y.iloc[train_idx]

        fit_kwargs = {}
        if use_balanced_weights:
            fit_kwargs["sample_weight"] = compute_sample_weight(
                class_weight="balanced",
                y=y_train,
            )

        estimator.fit(X_train, y_train, **fit_kwargs)

        # XGBoost on CUDA warns when predicting from CPU input; switch predictor device for inference.
        if force_cpu_predict and hasattr(estimator, "get_booster"):
            estimator.get_booster().set_param({"device": "cpu"})

        y_pred.iloc[test_idx[0]] = estimator.predict(X_test)[0]

    return y_pred


def main():
    warnings.filterwarnings("ignore", category=FutureWarning)

    engine = create_engine(DB_URL)
    df = load_subject_dataset(engine, COURSE_ID)

    if df.empty:
        print("No eligible subject rows found. Check COURSE_ID or data completeness.")
        return

    print(f"Loaded {len(df)} subjects for modeling.")
    print("Class distribution (actual_grade):")
    print(df["actual_grade"].value_counts().sort_index().to_string())

    feature_cols = [
        "assessments_count",
        "missing_score_count",
        "avg_unweighted_mark",
        "std_unweighted_mark",
        "min_unweighted_mark",
        "max_unweighted_mark",
        "total_weight",
        "total_weighted_mark",
        "potential_mark",
    ]

    X = df[feature_cols].copy()
    y = df["actual_grade"].copy()
    cv = LeaveOneOut()

    model = build_model(MODEL_BACKEND)
    using_xgboost_gpu = MODEL_BACKEND == "xgboost-gpu"

    baseline = DummyClassifier(strategy="most_frequent")

    unique_classes = y.nunique()
    if unique_classes < 2:
        print("Need at least 2 grade classes to train a classifier.")
        return

    label_encoder = None
    y_for_fit = y
    y_for_eval = y

    if using_xgboost_gpu:
        label_encoder = LabelEncoder()
        y_for_fit = pd.Series(
            label_encoder.fit_transform(y),
            index=y.index,
            name="encoded_grade",
        )
        y_for_eval = y

    if using_xgboost_gpu:
        y_pred_model_raw = loo_predict(
            model,
            X,
            y_for_fit,
            use_balanced_weights=True,
            force_cpu_predict=True,
        )
        y_pred_model = pd.Series(
            label_encoder.inverse_transform(y_pred_model_raw.astype(int)),
            index=y.index,
        )
    else:
        y_pred_model = cross_val_predict(model, X, y_for_fit, cv=cv, method="predict")

    y_pred_base = cross_val_predict(baseline, X, y, cv=cv, method="predict")

    model_acc = accuracy_score(y_for_eval, y_pred_model)
    base_acc = accuracy_score(y, y_pred_base)

    print("\n=== Leave-One-Out Validation ===")
    print(f"Model accuracy:    {model_acc:.3f}")
    print(f"Baseline accuracy: {base_acc:.3f}")

    labels = sorted(y.unique())
    print("\nClassification report:")
    print(classification_report(y_for_eval, y_pred_model, labels=labels, zero_division=0))

    cm = pd.DataFrame(
        confusion_matrix(y_for_eval, y_pred_model, labels=labels),
        index=[f"Actual_{c}" for c in labels],
        columns=[f"Pred_{c}" for c in labels],
    )
    print("Confusion matrix:")
    print(cm.to_string())

    # Fit on all rows so you can inspect in-sample class probabilities by subject.
    if using_xgboost_gpu:
        full_sample_weight = compute_sample_weight(class_weight="balanced", y=y_for_fit)
        model.fit(X, y_for_fit, sample_weight=full_sample_weight)
        model.get_booster().set_param({"device": "cpu"})
    else:
        model.fit(X, y_for_fit)
    probs = model.predict_proba(X)

    if label_encoder is not None:
        class_names = list(label_encoder.classes_)
        predicted_grade = pd.Series(
            label_encoder.inverse_transform(model.predict(X)),
            name="predicted_grade",
        )
    else:
        if hasattr(model, "named_steps") and "clf" in model.named_steps:
            class_names = list(model.named_steps["clf"].classes_)
        else:
            class_names = list(getattr(model, "classes_", labels))
        predicted_grade = pd.Series(model.predict(X), name="predicted_grade")

    prob_df = pd.DataFrame(probs, columns=[f"p_{c}" for c in class_names])
    out = pd.concat(
        [
            df[["subject_name", "actual_mark", "potential_mark", "actual_grade"]].reset_index(drop=True),
            predicted_grade,
            prob_df,
        ],
        axis=1,
    )

    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(parents=True, exist_ok=True)

    out_file = output_path / "subject_grade_predictions.csv"
    out.to_csv(out_file, index=False)

    model_file = output_path / "subject_grade_classifier.pkl"
    with open(model_file, "wb") as f:
        pickle.dump(model, f)

    metadata = {
        "created_at_utc": datetime.now(UTC).isoformat(),
        "course_id": COURSE_ID,
        "rows_used": int(len(df)),
        "features": feature_cols,
        "classes": list(class_names),
        "model_backend": MODEL_BACKEND,
        "validation": {
            "method": "LeaveOneOut",
            "model_accuracy": float(model_acc),
            "baseline_accuracy": float(base_acc),
        },
    }

    metadata_file = output_path / "subject_grade_classifier_metadata.json"
    with open(metadata_file, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    clf = model.named_steps["clf"] if hasattr(model, "named_steps") else model
    coef_file = output_path / "subject_grade_classifier_coefficients.csv"
    if hasattr(clf, "coef_"):
        coef_df = pd.DataFrame(clf.coef_, columns=feature_cols)
        coef_df.insert(0, "class", clf.classes_)
        coef_df.to_csv(coef_file, index=False)
        print(f"Saved coefficient table to {coef_file}")

    print(f"\nSaved per-subject predictions to {out_file}")
    print(f"Saved trained model artifact to {model_file}")
    print(f"Saved model metadata to {metadata_file}")


if __name__ == "__main__":
    main()
