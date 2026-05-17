#!/usr/bin/env python3
import sys

# Process rows piped from the HDFS split stream
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        number = int(line)
        if number > 50:  # Simple threshold filter evaluation
            print(number)
    except ValueError:
        continue