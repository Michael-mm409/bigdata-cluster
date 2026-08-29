FROM ubuntu:24.04

ARG SPARK_VERSION=3.5.9

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        python3.12 \
        python3-pip \
        curl \
        aria2 \
        ca-certificates \
        procps && \
    rm -rf /var/lib/apt/lists/*

ARG SPARK_VERSION=3.5.9

RUN aria2c \
    --max-connection-per-server=8 \
    --split=8 \
    --min-split-size=1M \
    --dir=/tmp \
    --out=spark.tgz \
    "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" && \
    tar -xzf /tmp/spark.tgz -C /opt && \
    rm /tmp/spark.tgz && \
    ln -s "/opt/spark-${SPARK_VERSION}-bin-hadoop3" /opt/spark

ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

ENV PYSPARK_PYTHON=python3.12
ENV PYSPARK_DRIVER_PYTHON=python3.12

WORKDIR /opt/spark
