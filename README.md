# Big Data Cluster

A self-hosted, Docker-based big data platform running **Hadoop (HDFS)**, **Spark**, **HBase**, **Hive**, and **Kafka** — deployable on a single laptop or split across a dedicated Mini PC brain and a GPU-powered desktop worker.

---

## Table of Contents

- [Quick Start](#-quick-start)
- [Deployment Modes](#-deployment-modes)
- [Repository Architecture](#-repository-architecture)
- [Configuration & Environment](#️-configuration--environment)
- [The Terminal Alias Superpower](#️-the-terminal-alias-superpower)
- [Cluster Web UI Dashboards](#-cluster-web-ui-dashboards)
- [Utility Scripts](#-utility-scripts)

---

## 🚀 Quick Start

### Option A — Distributed Mode (Mini PC Brain + Desktop GPU Worker)

> **Prerequisite:** The Mini PC must be reachable via SSH as the `minipc` Docker context.

```bash
# 1. Clone the repo
git clone <repo-url> && cd Big-Data-Cluster

# 2. Copy and fill in your network IPs
cp .env.example .env && nano .env

# 3. Fire up the full cluster (one command)
chmod +x infra/start-cluster.sh && ./infra/start-cluster.sh
```

`infra/start-cluster.sh` will:
1. Verify SSH connectivity to the Mini PC
2. Deploy the **Brain services** (NameNode, Spark Master, Kafka, HBase, Hive, ZooKeeper) to the Mini PC via remote Docker context
3. Wait 12 seconds for core services to stabilize
4. Deploy the **Worker services** (Spark Worker + GPU, DataNode, Stream Processor) locally on the Desktop

---

### Option B — Portable Mode (Single Laptop / VM)

No Mini PC needed. Everything runs on one machine using loopback addresses.

```bash
# Build the custom Spark base image first
docker build -t mds-spark:3.12 ./apps/spark-base-312

# Spin up the full stack on one machine
docker compose -f infra/docker-compose-portable.yml up -d --build
```

---

### Tear Down

```bash
# Distributed mode
docker --context minipc compose -f infra/docker-compose-brain.yml down
docker compose -f infra/desktop-worker-compose.yml down

# Portable mode
docker compose -f infra/docker-compose-portable.yml down
```

---

## 🗺 Deployment Modes

| Mode | When to use | Compose file(s) |
|---|---|---|
| **Distributed** | Mini PC is on the network as `minipc` Docker context | `infra/docker-compose-brain.yml` + `infra/desktop-worker-compose.yml` |
| **Portable** | Single machine, laptop, or local dev | `infra/docker-compose-portable.yml` |

Switch between modes by just changing which compose file you target — no code changes needed.

---

## 📦 Repository Architecture

```
Big-Data-Cluster/
│
├── apps/                              # Containerised application images
│   ├── bigdata-workbench/             #   Dev shell: Pig, Hive client, Python tooling
│   ├── spark-base-312/                #   Custom Spark 3.x base image (Python 3.12 + PySpark)
│   └── streaming-app/                 #   Real-time Kafka stream processor
│
├── courses/                           # University coursework (machine-specific symlinks gitignored)
│   ├── ISIT312/                       #   Big Data (prior course)
│   └── CSC6002 → <your local path>    #   Big Data Management — symlink, see below
│
├── infra/                             # Cluster infrastructure
│   ├── docker-compose-brain.yml       #   Brain: NameNode, Spark Master, Kafka, HBase, Hive, ZooKeeper
│   ├── desktop-worker-compose.yml     #   Workers: Spark Worker (GPU), DataNode, Stream Processor
│   ├── docker-compose-portable.yml    #   All-in-one: full stack on a single machine
│   ├── hadoop_config/                 #   HDFS XML configs shared via volume mount
│   ├── hadoop_data/                   #   DataNode block storage (runtime, gitignored)
│   ├── start-cluster.sh               #   One-shot distributed cluster launcher
│   ├── check_cluster.sh               #   Live health report: containers, resources, connectivity
│   ├── cluster_benchmark.py           #   Performance benchmarking suite
│   ├── getGpusResources.sh            #   GPU discovery script for Spark resource scheduling
│   └── hive-jdbc-client.jar           #   Hive JDBC driver for external client connections
│
├── ml/                                # Machine learning experiments
│   ├── train_subject_grade_model.py   #   Postgres-backed subject grade classifier
│   └── model_artifacts/               #   Trained model outputs (pkl, metadata — gitignored)
│
├── .env.example                       # Safe IP/config template — copy to .env
└── README.md
```

### Setting up the `courses/CSC6002` symlink

The CSC6002 folder lives in a different location on each machine and is gitignored. Create the symlink once after cloning:

```bash
# Desktop (example path)
ln -s "/mnt/Data/University/USQ/Masters of Data Science/Year 1/Trimester 2/CSC6002 - Big Data Management" courses/CSC6002

# Laptop (adjust path to match where your files actually are)
ln -s "/path/to/CSC6002 - Big Data Management" courses/CSC6002
```

### Service Map

| Service | Container | Role |
|---|---|---|
| **HDFS NameNode** | `namenode` | HDFS metadata and namespace |
| **HDFS DataNode** | `datanode` / `hadoop_worker` | Block storage |
| **YARN ResourceManager** | `resourcemanager` | Hadoop job scheduling |
| **Spark Master** | `spark-master` | Distributed compute coordinator |
| **Spark Worker** | `spark-worker` | GPU-accelerated compute executor |
| **HBase Master** | `hbase-master` | NoSQL wide-column store |
| **Hive Metastore** | `hive-metastore` | SQL schema catalog (Thrift) |
| **Hive Metastore DB** | `hive-metastore-db` | Postgres backing store for Hive |
| **Kafka** | `kafka-master` | KRaft-mode event streaming broker |
| **ZooKeeper** | `zookeeper` | Coordination service for HBase |
| **Stream Processor** | `stream-worker` | Kafka consumer → Postgres pipeline |
| **Workbench** | `bigdata-workbench` | Interactive dev shell (Pig, Hive, Python) |

---

## ⚙️ Configuration & Environment

All IP addresses and resource limits live in a single `.env` file — the only file you need to change when moving between machines.

```bash
cp .env.example .env
```

```ini
# .env

MASTER_IP=192.168.0.2    # IP of the Mini PC running the Brain services
DB_IP=192.168.0.3        # IP of the machine running Postgres / external DB
MY_IP=192.168.0.4        # IP of this machine (the Desktop worker)
WORKER_RAM=16G           # Memory ceiling for the Spark worker container
```

### Laptop / Loopback Mode

To run everything locally without a Mini PC, point all IPs at loopback:

```ini
MASTER_IP=127.0.0.1
DB_IP=127.0.0.1
MY_IP=127.0.0.1
WORKER_RAM=4G
```

Then use `docker-compose-portable.yml` — no SSH or remote Docker context required.

---

## ⌨️ The Terminal Alias Superpower

Stop typing `docker exec -it <container> <command>` for every interaction. Add these aliases to your `~/.zshrc` or `~/.bashrc` once, and your terminal becomes a native cluster client.

```bash
# ~/.zshrc  ─────────────────────────────────────────────────
# Big Data Cluster — Shell Aliases

# HDFS & Hadoop → NameNode container
alias hdfs='docker exec -it namenode hdfs'
alias hadoop='docker exec -it namenode hadoop'

# Spark & Pig → Workbench container
alias spark-submit='docker exec -it bigdata-workbench spark-submit'
alias pyspark='docker exec -it bigdata-workbench pyspark'
alias pig='docker exec -it bigdata-workbench pig'

# HBase → drops directly into the HBase shell
alias hbase='docker exec -it hbase-master hbase shell'
# ─────────────────────────────────────────────────────────────
```

```bash
source ~/.zshrc   # apply immediately
```

### Usage After Aliasing

```bash
# List HDFS root — no docker exec needed
hdfs dfs -ls /

# Run a PySpark job from any directory on your local machine
spark-submit /opt/spark-apps/my_job.py

# Open an interactive PySpark REPL
pyspark

# Drop into the HBase shell
hbase

# Run a Pig Latin script
pig -f /opt/spark-apps/my_transform.pig

# Check HDFS disk usage
hadoop fs -du -h /
```

---

## 📊 Cluster Web UI Dashboards

All UIs are accessible from your browser once the cluster is running. In **distributed mode**, substitute `localhost` with your `MASTER_IP` for Brain services.

| Service | URL | Notes |
|---|---|---|
| **Spark Master** | http://localhost:8085 | Workers, active jobs, resource usage |
| **HDFS NameNode** | http://localhost:9870 | HDFS health, DataNode list, block reports |
| **YARN ResourceManager** | http://localhost:8088 | Hadoop job queue and application history |
| **HBase Master** | http://localhost:16010 | Region servers, table stats |
| **Hive Metastore (Thrift)** | `localhost:9083` | Not a browser UI — JDBC/Beeline endpoint |
| **Kafka Broker** | `localhost:9092` | Not a browser UI — producer/consumer endpoint |
| **ZooKeeper** | `localhost:2181` | Not a browser UI — coordination endpoint |

---

## 🛠 Utility Scripts

| Script | What it does |
|---|---|
| `./infra/start-cluster.sh` | Full distributed launch: SSH to Mini PC → deploy brain → deploy workers |
| `./infra/check_cluster.sh` | Live health snapshot: container status, CPU/memory usage, Mini PC reachability |
| `python infra/cluster_benchmark.py` | Runs a performance benchmark suite against the running cluster |
| `./infra/getGpusResources.sh` | GPU resource discovery script — used internally by the Spark worker |

### Health Check

```bash
./infra/check_cluster.sh
```

```
------------------------------------------------
🖥️  DESKTOP WORKER STATUS - Sat May 17 ...
------------------------------------------------
📦 Active Containers:
NAME            STATUS          PORTS
spark-worker    Up 3 minutes    ...
kafka-master    Up 3 minutes    ...
hadoop_worker   Up 3 minutes    ...

📊 Resource Usage (Memory/CPU):
NAME            CPU %    MEM USAGE       MEM %
spark-worker    12.4%    3.1GiB/16GiB    19.4%
...

🔗 Connectivity to Mini PC (Master):
✅ Master (192.168.8.10) is REACHABLE
------------------------------------------------
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose v2 | `docker compose` (not `docker-compose`) |
| NVIDIA Container Toolkit | Only for GPU worker — `nvidia-ctk` + driver |
| SSH access to Mini PC | Distributed mode only — set up `minipc` Docker context |
| 8 GB+ RAM | 16 GB recommended for full distributed stack |

### Setting Up the `minipc` Docker Context (Distributed Mode Only)

```bash
docker context create minipc \
  --docker "host=ssh://Michael@<MASTER_IP>"

# Verify
docker --context minipc info
```

---

*Built for homelab experimentation and big data learning. Swap IPs in `.env`, run one script, and you have a production-grade data platform on commodity hardware.*
