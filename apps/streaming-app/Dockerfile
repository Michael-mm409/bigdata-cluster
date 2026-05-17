FROM python:3.11-slim
WORKDIR /app
RUN pip install pyspark confluent-kafka
COPY . .
CMD ["python", "processor.py"]
