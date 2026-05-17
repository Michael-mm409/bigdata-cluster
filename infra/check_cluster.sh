#!/bin/bash

# --- Big Data Cluster Health Report ---
echo "------------------------------------------------"
echo "🖥️  DESKTOP WORKER STATUS - $(date)"
echo "------------------------------------------------"

# 1. Check Container Status
echo "📦 Active Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "spark|kafka|hadoop|processor"

echo -e "\n📊 Resource Usage (Memory/CPU):"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# 2. Check Master Connection
echo -e "\n🔗 Connectivity to Mini PC (Master):"
if ping -c 1 192.168.8.10 &> /dev/null
then
    echo "✅ Master (192.168.8.10) is REACHABLE"
else
    echo "❌ Master (192.168.8.10) is UNREACHABLE"
fi

echo "------------------------------------------------"

