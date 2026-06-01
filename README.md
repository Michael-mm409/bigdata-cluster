# Big Data Cluster

A self-hosted, Docker-based data platform for Big Data coursework (CSC6002) and experimentation — running **Spark**, **HDFS (Hadoop)**, and **MongoDB** on a single machine, with built-in data sync, JupyterLab, and PyTorch GPU support.

---

## Table of Contents

- [Quick Start](#-quick-start)
- [Repository Architecture](#-repository-architecture)
- [Service Map](#service-map)
- [Custom Image — `mds-spark:3.12`](#-custom-image--mds-spark312)
- [Configuration & Environment](#️-configuration--environment)
- [Shell Aliases](#️-shell-aliases)
- [Web UI Dashboards](#-web-ui-dashboards)
- [Utility Scripts](#-utility-scripts)
- [Data Sync Workflow](#-data-sync-workflow)
- [Prerequisites](#prerequisites)

---

## 🚀 Quick Start

```bash
# 1. Clone the repo
git clone <repo-url> && cd Big-Data-Cluster

# 2. Run the Arch Linux setup script (installs Docker, DBeaver, MongoDB Compass, mongosh)
chmod +x infra/setup_course_env.sh && ./infra/setup_course_env.sh

# 3. Copy and fill in your environment config
cp .env.example .env && nano .env

# 4. Build the custom Spark image and start all services
docker compose up -d --build
```

> The `--build` flag is only required on first run or after changes to `apps/spark-base-312/Dockerfile`.
> Subsequent starts use the cached image: `docker compose up -d`.

### What starts

`docker compose up -d` launches the full stack defined in `docker-compose.yml` (repo root):

| Step | What happens |
|---|---|
| 1 | MongoDB container (`course-mongodb`) starts on port `27017` |
| 2 | `namenode` initialises HDFS and writes `hadoop_config/` XML files to the bind mount |
| 3 | `datanode` connects to NameNode and registers block storage |
| 4 | `spark-master` starts the Spark Master UI on port `8085` |
| 5 | Two `spark-worker` replicas connect to the master via `spark://spark-master:7077` |

### Tear Down

```bash
docker compose down
```

To wipe all named volumes (destroys HDFS NameNode data):

```bash
docker compose down -v
```

---

## 📦 Repository Architecture

```
Big-Data-Cluster/
│
├── apps/
│   └── spark-base-312/
│       └── Dockerfile             # Custom image: Python 3.12, PySpark 3.5.1, PyTorch, JupyterLab
│
├── courses/
│   └── ISIT312/                   # Prior course (Big Data) reference scripts
│
├── data/
│   └── mongodb_dumps/             # Tracked MongoDB collection exports (JSON arrays)
│       └── .gitkeep
│
├── infra/
│   ├── cluster_benchmark.py       # Monte Carlo Pi benchmark — 500M samples via Spark
│   ├── hadoop_config/             # Auto-generated HDFS XML configs (gitignored, written at runtime)
│   ├── hadoop_data_local/         # DataNode block storage bind-mount (gitignored)
│   ├── mongo_data/                # MongoDB data directory bind-mount (gitignored)
│   ├── setup_course_env.sh        # One-time machine setup (Arch Linux / pacman)
│   └── sync_labs.sh               # Lab data sync: --pull seeds containers, --push exports + commits
│
├── ml/
│   ├── train_subject_grade_model.py
│   └── model_artifacts/           # Trained model outputs (gitignored)
│
├── docker-compose.yml             # ← Single compose file for the full stack (repo root)
├── .env.example                   # Safe IP/config template — copy to .env
├── requirements.txt               # Python dependencies for host-side tooling
├── zshrc_aliases.txt              # Shell aliases to copy into ~/.zshrc
└── README.md
```

### Setting up the `courses/CSC6002` symlink

The CSC6002 folder path differs per machine and is gitignored. Create the symlink once after cloning:

```bash
# Desktop (adjust path to match your local structure)
ln -s "/mnt/Data/University/USQ/Masters of Data Science/Year 1/Trimester 2/CSC6002 – Big Data Management" courses/CSC6002

# Laptop
ln -s "/path/to/CSC6002 - Big Data Management" courses/CSC6002
```

---

## Service Map

All services are defined in `docker-compose.yml` at the repository root and share the `bigdata-net` bridge network.

| Service | Container Name | Image | Role | Ports |
|---|---|---|---|---|
| **Spark Master** | `spark-master` | `mds-spark:3.12` (custom build) | Distributed compute coordinator | `8085` → UI, `7077` → submit |
| **Spark Worker** | *(auto-named, ×2 replicas)* | `mds-spark:3.12` (custom build) | Compute executor — 4 cores / `${WORKER_RAM}` each | — |
| **HDFS NameNode** | `namenode` | `bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8` | HDFS metadata, namespace, config generator | `9870` → UI, `9000` → RPC |
| **HDFS DataNode** | `datanode` | `bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8` | HDFS block storage (bind-mount at `infra/hadoop_data_local/`) | — |
| **MongoDB** | `course-mongodb` | `mongo:7.0` | Course lab database (bind-mount at `infra/mongo_data/`) | `27017` |

### Volumes and Bind Mounts

| Mount | Type | Purpose |
|---|---|---|
| `namenode_data` | Named volume | Persistent HDFS NameNode metadata |
| `infra/mongo_data/` | Host bind | MongoDB data directory |
| `infra/hadoop_data_local/` | Host bind | DataNode block storage |
| `${COURSE_WORKSPACE}` → `/opt/spark-apps/` | Host bind | Course workspace files accessible inside Spark containers |
| `../` → `/opt/cluster-workspace` | Host bind | Repo root accessible inside NameNode container |


---

## 🐳 Custom Image — `mds-spark:3.12`

Built from `apps/spark-base-312/Dockerfile`. Used by both `spark-master` and `spark-worker`.

| Layer | Component | Version |
|---|---|---|
| Base | Python (slim) | 3.12 |
| Runtime | Java (OpenJDK headless) | 21 |
| Hadoop client | Apache Hadoop (binaries only) | 3.3.6 |
| Spark | PySpark | 3.5.1 |
| ML stack | NumPy, Pandas, scikit-learn, SciPy, Matplotlib | latest |
| Deep learning | PyTorch + torchvision + torchaudio | CUDA 12.1 build |
| Notebook | JupyterLab | latest |
| JDBC drivers | `thrift`, `jaydebeapi`, `hdfs` | — |

**Default CMD** (Dockerfile): starts JupyterLab on port `8888`.
**Overridden by `docker-compose.yml`**: `spark-master` runs the Spark Master process; `spark-worker` replicas run the Spark Worker process.

To spin up an ad-hoc JupyterLab session against the running cluster:

```bash
docker run --rm -it \
  --network bigdata-net \
  -p 8888:8888 \
  -v "${COURSE_WORKSPACE}:/opt/spark-apps" \
  mds-spark:3.12
```

---

## ⚙️ Configuration & Environment

All tuneable values live in `.env`. Copy the example and edit before first run:

```bash
cp .env.example .env
```

### Environment Variables

| Variable | Example Value | Used by | Purpose |
|---|---|---|---|
| `WORKER_RAM` | `8G` | `docker-compose.yml` | Memory limit **and** `SPARK_WORKER_MEMORY` for each Spark worker |
| `COURSE_WORKSPACE` | `/path/to/your/workspace` | `docker-compose.yml` | Host path bind-mounted into Spark containers at `/opt/spark-apps/` |

```ini
# .env — complete example

WORKER_RAM=8G
COURSE_WORKSPACE="/mnt/Data/University/USQ/Masters of Data Science/Year 1/Trimester 2/CSC6002 – Big Data Management/"
```

### Laptop / Low-Resource Override

```ini
WORKER_RAM=4G
COURSE_WORKSPACE=/home/youruser/CSC6002
```

---

## ⌨️ Shell Aliases

Copy the contents of `zshrc_aliases.txt` into your `~/.zshrc` (or `~/.bashrc`), then reload:

```bash
cat zshrc_aliases.txt >> ~/.zshrc && source ~/.zshrc
```

### Available Aliases

```bash
# HDFS operations via NameNode container
alias hdfs="docker exec -i namenode hdfs"
alias hadoop="docker exec -i namenode hadoop"

# Spark operations via Spark Master container
alias pyspark="docker exec -it spark-master pyspark"
alias spark-submit="docker exec -it spark-master spark-submit"

# MongoDB shell — drops into the specified database (default: uni_sandbox)
mongosh() {
    local db_name="${1:-uni_sandbox}"
    docker exec -it course-mongodb mongosh "$db_name"
}

# Cluster lifecycle — start/stop with automatic data sync
cluster-up()    # docker compose up -d  +  sync_labs.sh --pull
cluster-down()  # sync_labs.sh --push   +  docker compose down

# Lab data sync shortcuts
alias lab-push="~/Big-Data-Cluster/infra/sync_labs.sh --push"
alias lab-pull="~/Big-Data-Cluster/infra/sync_labs.sh --pull"
```

> **Known issue in `zshrc_aliases.txt`:** `cluster-up` and `cluster-down` reference `~/Big-Data-Cluster/infra/docker-compose.yml`, but the compose file lives at the **repo root** (`~/Big-Data-Cluster/docker-compose.yml`). Update that path after copying the aliases.

### Usage Examples

```bash
# List HDFS root directory
hdfs dfs -ls /

# Check HDFS disk usage
hadoop fs -du -h /

# Submit a PySpark job from any directory
spark-submit /opt/spark-apps/my_job.py

# Open an interactive PySpark REPL
pyspark

# Drop into MongoDB shell (uni_sandbox)
mongosh

# Drop into a specific database
mongosh csc6002

# Full cluster lifecycle with data sync
cluster-up
cluster-down
```

---

## 📊 Web UI Dashboards

All UIs are accessible from your browser once the stack is running.

| Service | URL | Notes |
|---|---|---|
| **Spark Master** | http://localhost:8085 | Worker list, active jobs, resource allocation |
| **HDFS NameNode** | http://localhost:9870 | HDFS health, DataNode registration, block reports |
| **MongoDB** | `localhost:27017` | Not a browser UI — connect via Compass or `mongosh` |

> YARN ResourceManager, HBase, Hive, Kafka, and ZooKeeper are **not** part of this stack. They exist in `requirements.txt` as client libraries for future extension.

---

## 🛠 Utility Scripts

| Script | What it does |
|---|---|
| `./infra/setup_course_env.sh` | One-time machine setup: `pacman` sync, Docker, DBeaver, MongoDB Compass, `mongosh`; verifies `mds-spark:3.12` image; creates bind-mount directories |
| `./infra/sync_labs.sh --pull` | `git pull` → ensure containers running → seed MongoDB from `data/mongodb_dumps/*.json` → push `data/` into HDFS |
| `./infra/sync_labs.sh --pull` | `git pull` → seed containers → push data into HDFS |
| `./infra/sync_labs.sh --push` | Export all active MongoDB collections to `data/mongodb_dumps/` → pull HDFS `/data` back to local → `git commit` + `git push` |
| `python infra/cluster_benchmark.py` | Monte Carlo Pi estimation using 500 million samples — distributed across Spark workers |

### Setup Script (`setup_course_env.sh`)

Designed for **Arch Linux** (`pacman`). On other distros, install the equivalent packages manually:

```bash
# Arch Linux
./infra/setup_course_env.sh

# Verify the Spark image was built
docker images mds-spark:3.12
```

### Data Sync Script (`sync_labs.sh`)

```bash
# Pull: update code + seed both storage tiers (MongoDB + HDFS)
./infra/sync_labs.sh --pull

# Push: export data snapshots, commit, and push to GitHub
./infra/sync_labs.sh --push

# Help
./infra/sync_labs.sh --help
```

---

## 🔄 Data Sync Workflow

The sync script manages a two-tier data layer (MongoDB + HDFS) across machines.

```
GitHub (remote)
     │
     │  git pull / git push
     ▼
Big-Data-Cluster/data/
├── mongodb_dumps/          ← JSON exports of MongoDB collections (tracked in Git)
│   └── csc6002.json
└── (other datasets)        ← CSV/TSV/JSON files are gitignored; only mongodumps are tracked
     │
     │  mongoimport / mongoexport
     ▼                      │
course-mongodb container     │  hdfs dfs -put / -get
(uni_sandbox database)      ▼
                    namenode + datanode containers
                    (HDFS /data directory)
```

### Workflow per machine

```bash
# Starting a new session (any machine)
cluster-up           # or: ./infra/sync_labs.sh --pull

# Ending a session (saves work back to Git)
cluster-down         # or: ./infra/sync_labs.sh --push
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose v2 | Use `docker compose` (not `docker-compose`) |
| Arch Linux (for setup script) | Or install equivalents manually on other distros |
| NVIDIA Container Toolkit | Optional — only required for GPU-accelerated PyTorch jobs |
| 8 GB+ RAM | 16 GB recommended; tune `WORKER_RAM` in `.env` |
| Git | Required by `sync_labs.sh` for data backup and pull |

### Building the custom Spark image manually

If the image is not yet cached locally:

```bash
docker build -t mds-spark:3.12 ./apps/spark-base-312
```

> The first build downloads PyTorch (CUDA 12.1 wheels — ~2 GB). Subsequent builds use the Docker layer cache.

---

*Built for homelab experimentation and Big Data coursework. Swap one `.env` file, run `docker compose up -d --build`, and you have a full Spark + HDFS + MongoDB stack ready for labs.*
