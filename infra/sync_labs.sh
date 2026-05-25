#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

# Define paths relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data"

# Ensure the shared data repository folder exists
mkdir -p "$DATA_DIR"

show_help() {
    echo "CSC6002 Environment Sync Utility"
    echo "Usage: ./sync_labs.sh [option]"
    echo ""
    echo "Options: "
    echo "  --pull    Pull latest Git code and seed local MongoDB/HDFS containers"
    echo "  --push    Export current local database states to Git and push to GitHub"
    echo "  --help    Show this help menu"
}

pull_and_seed() {
    echo "🔄 Pulling latest changes from GitHub..."
    git -C "$SCRIPT_DIR/.." pull

    echo "🚀 Ensuring Docker containers are running..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

    echo "⏳ Waiting for databases and storage clusters to warm up..."
    sleep 5

    # --- MONGO SEED SECTION ---
    if [ -f "$DATA_DIR/mongo_coursework.json" ]; then
        echo "📥 Seeding MongoDB with tracked datasets..."
        docker exec -i course-mongodb mongoimport \
            --db uni_sandbox \
            --collection assignments \
            --drop \
            --jsonArray < "$DATA_DIR/mongo_coursework.json"
    else
        echo "ℹ️ No MongoDB seed file found in data/. Skipping import."
    fi

    # --- HADOOP HDFS SEED SECTION ---
    if [ "$(ls -A "$DATA_DIR")" ]; then
        echo "📥 Pushing structured repository datasets into Hadoop HDFS..."

        # 🌟 FIX: Wipe the old virtual HDFS /data folder first if it exists to prevent nested data/data structures
        docker exec -i namenode hdfs dfs -rm -r -f /data 2>/dev/null || true

        # Copy the entire data folder tree recursively into the HDFS workspace root
        docker exec -i namenode hdfs dfs -put -f /opt/cluster-workspace/data /
        echo "✅ Hadoop HDFS storage tier completely synchronized!"
    else
        echo "ℹ️ No local datasets found in data/. Skipping HDFS import."
    fi

    echo "✅ Environment completely online and ready for labs!"
}

export_and_push() {
    echo "🚀 Ensuring Docker containers are running to perform export..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

    # --- MONGO EXPORT SECTION ---
    echo "📤 Exporting active MongoDB collections..."
    docker exec -i course-mongodb mongoexport \
        --db uni_sandbox \
        --collection assignments \
        --jsonArray > "$DATA_DIR/mongo_coursework.json"

    # --- HADOOP HDFS EXPORT SECTION ---
    echo "📤 Extracting all structured data out of the Hadoop HDFS layer..."

    # Safely pull the recursive folder tree back down out of the cluster
    if docker exec -i namenode hdfs dfs -test -e /data 2>/dev/null; then
        # The wildcard here is fine because we are targeting files within HDFS to drop into local data/
        docker exec -i namenode hdfs dfs -get -f /data/* /opt/cluster-workspace/data/
    else
        echo "ℹ️ The internal HDFS /data directory is currently empty. Skipping export."
    fi

    echo "💾 Staging changes to Git tracking timeline..."
    git -C "$SCRIPT_DIR/.." add "$DATA_DIR/"

    # Only commit if there are actual database or dataset changes present
    if ! git -C "$SCRIPT_DIR/.." diff-index --quiet HEAD -- "$DATA_DIR/"; then

        # 🌟 AUTOMATION: Dynamically detect hostname and timestamp
        HOST_IDENTITY=$(hostname)
        TIMESTAMP=$(date +"%d/%m/%Y %H:%M")
        COMMIT_MSG="data: snapshot [$HOST_IDENTITY] on $TIMESTAMP"

        echo "📝 Committing with self-documenting log: '$COMMIT_MSG'"
        git -C "$SCRIPT_DIR/.." commit -m "$COMMIT_MSG"

        echo "🚀 Pushing synchronised data backups to GitHub..."
        git -C "$SCRIPT_DIR/.." push origin main
        echo "✅ Data successfully backed up to cloud repository!"
    else
        echo "ℹ️ No data modifications detected. Git timeline is completely clean."
    fi
}

# Parse incoming command line arguments
case "$1" in
    --pull)
        pull_and_seed
        ;;
    --push)
        export_and_push
        ;;
    *)
        show_help
        exit 1
        ;;
esac
