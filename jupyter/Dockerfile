FROM quay.io/jupyter/base-notebook:latest

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt

RUN python3 -m pip install \
    --break-system-packages \
    --no-cache-dir \
    -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

USER jovyan

WORKDIR /course
