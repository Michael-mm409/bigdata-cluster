FROM python:3.12-slim

# Avoid interactive prompts during installation layers
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install base system utilities, networking hooks, build tools, and Java 21
# Includes build-essential and libgomp1 required for C++ compiled ML models
RUN apt-get update && \
    apt-get install -y procps curl wget tar git build-essential libgomp1 openjdk-21-jre-headless && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# 2. Install a lightweight standalone Hadoop client framework (For MapReduce execution blocks)
ENV HADOOP_VERSION=3.3.6
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# 3. Expose Hadoop Binary Execution Paths to System Environments
ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION}
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# 4. Install the pure Python gateway drivers and PySpark Ecosystem
RUN pip install --no-cache-dir \
    pyspark==3.5.1 \
    hdfs \
    thrift \
    jaydebeapi

# =========================================================================
# 🚀 MACHINE LEARNING & ACCELERATED DATA SCIENCE LAYER
# =========================================================================

# 5. Install baseline data manipulation frameworks and JupyterLab interface
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    scipy \
    matplotlib \
    jupyterlab \
    notebook

# 6. Install PyTorch explicitly targeting CUDA accelerated architectures
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Reset default workspace target directory
WORKDIR /opt/spark-apps

# 7. Expose JupyterLab's default communications port
EXPOSE 8888

# 8. Launch Thread: Fire up an open Jupyter Server on boot
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
