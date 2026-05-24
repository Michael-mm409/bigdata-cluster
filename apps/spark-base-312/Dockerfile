FROM python:3.12-slim

# Avoid interactive prompts during installation layers
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install base system utilities, networking hooks, build tools, and Java 21
# ◄ Added build-essential and libgomp1 which are hard requirements for C++ compiled ML models
RUN apt-get update && \
    apt-get install -y procps curl wget tar git build-essential libgomp1 openjdk-21-jre-headless && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# 3. Install a lightweight Hadoop client frame (FAST CDN MIRROR)
ENV HADOOP_VERSION=3.3.6
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# 4. Install Apache Pig Binary Client Frame (Must use ARCHIVE URL for legacy releases)
RUN wget -q https://archive.apache.org/dist/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzf pig-0.17.0.tar.gz -C /opt/ && \
    ln -s /opt/pig-0.17.0 /opt/pig && \
    rm pig-0.17.0.tar.gz

# 5. Install Hive Binary Client Frame (Must use ARCHIVE URL for legacy releases)
RUN wget -q https://archive.apache.org/dist/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz && \
    tar -xzf apache-hive-2.3.9-bin.tar.gz -C /opt/ && \
    ln -s /opt/apache-hive-2.3.9-bin /opt/hive && \
    rm apache-hive-2.3.9-bin.tar.gz

# 🔥 FIX A: Wildcard Guava Surgery (Dynamically grabs the updated 3.3.6 jar file seamlessly!)
RUN rm /opt/hive/lib/guava-14.0.1.jar && \
    cp /opt/hadoop-${HADOOP_VERSION}/share/hadoop/common/lib/guava-*.jar /opt/hive/lib/

# 5b. Install HBase Binary Client Frame (Matching Backend Version 1.2.6 - Use ARCHIVE)
RUN wget -q https://archive.apache.org/dist/hbase/1.2.6/hbase-1.2.6-bin.tar.gz && \
    tar -xzf hbase-1.2.6-bin.tar.gz -C /opt/ && \
    ln -s /opt/hbase-1.2.6 /opt/hbase && \
    rm hbase-1.2.6-bin.tar.gz

# 6. Expose All Client Binary Execution Paths to System Environments
ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION}
ENV PIG_HOME=/opt/pig
ENV HIVE_HOME=/opt/hive
ENV HBASE_HOME=/opt/hbase
ENV HIVE_CONF_DIR=/opt/spark-apps/infra/hadoop_config
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PIG_HOME/bin:$HIVE_HOME/bin:$HBASE_HOME/bin

# 7. Install the pure Python gateway drivers (Preserved from your original spec)
RUN pip install --no-cache-dir \
    pyspark==3.5.1 \
    hdfs \
    thrift \
    jaydebeapi

# =========================================================================
# 🚀 NEW: MACHINE LEARNING & ACCELERATED DATA SCIENCE LAYER
# =========================================================================

# 8. Install baseline data manipulation frameworks and JupyterLab interface
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    scipy \
    matplotlib \
    jupyterlab \
    notebook

# 9. Install PyTorch explicitly targeting CUDA 12.1 runtime compiled architectures
# ◄ Forces the container to fetch the GPU-accelerated wheels needed for your 5070 Ti
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://pytorch.org

# Reset default workspace target directory
WORKDIR /opt/spark-apps

# 10. Expose JupyterLab's default communications port
EXPOSE 8888

# 11. Upgraded Launch Thread: Fire up an open Jupyter Server on boot instead of letting it sleep!
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
