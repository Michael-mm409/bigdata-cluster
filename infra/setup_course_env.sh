#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Clear text color formatting
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}     UniSQ Data Science Tool Stack Setup Script     ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. System Sync & Native Desktop Tool Installation
echo -e "\n${YELLOW}[1/4] Synchronizing system repos and installing DBeaver...${NC}"
sudo pacman -Syu --needed dbeaver docker docker-compose

# 2. AUR Package Installation via Paru (MongoDB Suite)
echo -e "\n${YELLOW}[2/4] Installing MongoDB Server and Compass via Paru...${NC}"
if ! command -v paru &> /dev/null; then
    echo -e "${YELLOW}Paru not detected. Attempting to fall back to yay...${NC}"
    yay -S --needed mongodb-bin mongodb-compass mongosh-bin
else
    paru -S --needed mongodb-bin mongodb-compass mongosh-bin
fi

# 3. Pull Streamlined Docker Images for Spark & Hadoop Core
echo -e "\n${YELLOW}[3/4] Pulling isolated cluster images from Docker Hub...${NC}"
# Pulling the core containers referenced in your portable compose configuration
docker pull bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8
docker pull bde2020/hadoop-datanode:2.0.0-hadoop3.2.1-java8
docker pull mongo:6.0

# Note on the custom PySpark base image
if docker image inspect mds-spark:3.12 &> /dev/null; then
    echo -e "${GREEN}✓ Local image mds-spark:3.12 is already present.${NC}"
else
    echo -e "${YELLOW}! Warning: mds-spark:3.12 image must be built locally or pulled from your private container registry if it isn't public.${NC}"
fi

# 4. Create Persistent Storage Bind Paths
echo -e "\n${YELLOW}[4/4] Verifying local directory layouts...${NC}"
mkdir -p /home/michael/Big-Data-Cluster/infra/mongo_data
mkdir -p /home/michael/Big-Data-Cluster/infra/hadoop_data_local
mkdir -p /home/michael/Big-Data-Cluster/infra/hadoop_config

echo -e "${GREEN}✓ Local persistent directory nodes verified.${NC}"

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}               SETUP COMPLETE!                      ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Next steps:"
echo -e "  1. Run your clean course stack: ${YELLOW}docker-compose up -d${NC}"
echo -e "  2. Connect your native ${YELLOW}DBeaver${NC} client to your relational test environments."
echo -e "  3. Open ${YELLOW}MongoDB Compass${NC} and connect to: ${GREEN}mongodb://localhost:27017${NC}"
echo -e "${BLUE}====================================================${NC}"
