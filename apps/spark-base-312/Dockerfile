FROM python:3.12-slim

# Avoid interactive prompts during installation layers
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install bare system utilities and Java 21 (Required for Spark to run)
RUN apt-get update && \
    apt-get install -y procps curl wget tar git build-essential openjdk-21-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Set Java Home (Spark needs this to spin up its JVM gateway)
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# 2. Install PySpark and basic cluster tools
RUN pip install --no-cache-dir \
    pyspark==3.5.1 \
    hdfs

# =========================================================================
# 📊 CORE DATA SCIENCE & INTERACTIVE INTERFACE
# =========================================================================

# 3. Install core data manipulation frameworks and JupyterLab
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    scipy \
    matplotlib \
    jupyterlab \
    notebook \
    pymongo

# 🔌 SAFE BACKWARD-COMPATIBILITY FALLBACK
# If Docker Compose doesn't feed a variable, it defaults to localhost
ENV MONGO_URI="mongodb://localhost:27017/csc6002_lab"

WORKDIR /opt/spark-apps

# Expose JupyterLab's default communications port
EXPOSE 8888

# 4. Fire up the Jupyter Server on boot (keeps the container alive seamlessly)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
