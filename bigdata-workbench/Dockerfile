FROM python:3.10-slim

# Avoid interactive prompts during installation layers
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install base system utilities and networking hooks
RUN apt-get update && \
    apt-get install -y procps curl wget tar && \
    rm -rf /var/lib/apt/lists/*

# 2. Download and unpack a rock-solid, pre-compiled Java 8 (OpenJDK 8) runtime binary
RUN wget -q https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u412-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u412b08.tar.gz && \
    tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u412b08.tar.gz -C /opt/ && \
    ln -s /opt/jdk8u412-b08 /opt/java && \
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u412b08.tar.gz

# Establish exact Java 8 Environment mapping definitions globally
ENV JAVA_HOME=/opt/java
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
ENV HIVE_CONF_DIR=/opt/spark-apps/hadoop_config
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PIG_HOME/bin:$HIVE_HOME/bin:$HBASE_HOME/bin

# 7. Install the pure Python gateway drivers (Upgraded PySpark to align with your Python 3.12 nodes!)
RUN pip install --no-cache-dir \
    pyspark==3.5.0 \
    hdfs \
    thrift \
    jaydebeapi

# Reset default workspace target directory
WORKDIR /opt/spark-apps

# Keep container idling smoothly in background awaiting execution threads
CMD ["tail", "-f", "/dev/null"]