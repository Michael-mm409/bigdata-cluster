FROM ubuntu:22.04

# Avoid prompts during installation layers
ENV DEBIAN_FRONTEND=noninteractive

# Install Java 8, standard system python3, and required build tools cleanly
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    procps \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Establish exact Java 8 Environment mapping definitions 
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# --- INSTALL APACHE PIG ---
RUN wget -q https://archive.apache.org/dist/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzf pig-0.17.0.tar.gz -C /opt/ && \
    ln -s /opt/pig-0.17.0 /opt/pig && \
    rm pig-0.17.0.tar.gz

# --- INSTALL HIVE CLIENT ---
RUN wget -q https://archive.apache.org/dist/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz && \
    tar -xzf apache-hive-2.3.9-bin.tar.gz -C /opt/ && \
    ln -s /opt/apache-hive-2.3.9-bin /opt/hive && \
    rm apache-hive-2.3.9-bin.tar.gz

# Set Binary Executable Navigation Paths
ENV PIG_HOME=/opt/pig
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$PIG_HOME/bin:$HIVE_HOME/bin

# Keep container idling smoothly in background awaiting execution threads
CMD ["tail", "-f", "/dev/null"]
