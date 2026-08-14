FROM ubuntu:24.04

ARG SPARK_VERSION=3.5.6

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        python3.12 \
        python3-pip \
        curl \
        ca-certificates \
        procps && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    | tar -xz -C /opt && \
    ln -s "/opt/spark-${SPARK_VERSION}-bin-hadoop3" /opt/spark

ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

ENV PYSPARK_PYTHON=python3.12
ENV PYSPARK_DRIVER_PYTHON=python3.12

WORKDIR /opt/spark
