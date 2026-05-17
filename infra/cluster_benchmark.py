from pyspark.sql import SparkSession
import random
import time

# 1. Initialize Spark Session pointing to your local Master
# The Master will then distribute the work to the Desktop Worker (.4)
spark = SparkSession.builder \
    .appName("MDS-Desktop-Direct-Run") \
    .master("spark://192.168.8.10:7077") \
    .config("spark.driver.host", "192.168.8.4") \
    .config("spark.driver.bindAddress", "0.0.0.0") \
    .getOrCreate()
    
def inside(p):
    x, y = random.random(), random.random()
    return x*x + y*y < 1

# 2. Define the scale (100 Million Samples)
num_samples = 500_000_000
print(f"🚀 Starting Monte Carlo Pi estimation with {num_samples} samples...")
start_time = time.time()

# 3. Distributed Computation
# This part is sent across the network to your Desktop!
count = spark.sparkContext.parallelize(range(0, num_samples)) \
             .filter(inside).count()

end_time = time.time()
pi = 4.0 * count / num_samples

print(f"✅ Finished in: {round(end_time - start_time, 2)} seconds")
print(f"🥧 Estimated Pi: {pi}")

spark.stop()
