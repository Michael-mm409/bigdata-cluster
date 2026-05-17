#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[1/4] Checking remote network link to the Brain (192.168.8.10)...${NC}"
if ! ssh -o ConnectTimeout=3 -q Michael@192.168.8.10 exit; then
    echo "❌ Error: Cannot connect to the Mini PC. Is it awake on the network?"
    exit 1
fi

echo -e "${GREEN}✔ Handshake Success!${NC}"
echo -e "${BLUE}[2/4] Remote deploying Core Brain Services to the Mini PC...${NC}"

# This reads your local brain blueprint file and boots it on the Mini PC hardware
docker --context minipc compose -f "$SCRIPT_DIR/docker-compose-brain.yml" up -d

echo -e "${BLUE}[3/4] Pausing 12 seconds for ZooKeeper, NameNode, and Kafka to wake up...${NC}"
sleep 12

echo -e "${BLUE}[4/4] Deploying Local GPU Worker Services to the Desktop...${NC}"
# This runs your local workers, mounts your GPU, and hooks up host networking
docker compose -f "$SCRIPT_DIR/desktop-worker-compose.yml" up -d

echo -e "${GREEN}✔ Your distributed cluster is officially online and data-ready!${NC}"
