FROM python:3.12-slim

# Install Java, procps, and CUDA math libraries with security override
RUN apt-get update && apt-get install -y \
    openjdk-21-jre-headless \
    procps \
    curl \
    && echo "deb [trusted=yes] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" \
    > /etc/apt/sources.list.d/cuda.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    libcurand-12-5 \
    libcublas-12-5 \
    libcufft-12-5 \
    libcusparse-12-5 \
    libcusolver-12-5 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    pyspark==3.5.1 \
    numpy \
    setuptools \
    pandas \
    scipy \
    scikit-learn \
    sqlalchemy \
    psycopg2-binary \
    xgboost \
    cupy-cuda12x

ENV SPARK_HOME=/usr/local/lib/python3.12/site-packages/pyspark
ENV PATH=$PATH:$SPARK_HOME/bin
