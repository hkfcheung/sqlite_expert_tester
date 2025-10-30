#!/bin/bash

# SQLite Expert Inference Runner Script
# This script simplifies running the inference tests on RTX 4090

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "SQLite Expert Inference Test Runner"
echo "=========================================="
echo ""

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}ERROR: nvidia-smi not found. Please install NVIDIA drivers.${NC}"
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker not found. Please install Docker.${NC}"
    exit 1
fi

# Check if NVIDIA Container Toolkit is working
echo "Checking NVIDIA GPU availability..."
if ! docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${RED}ERROR: NVIDIA Container Toolkit not working properly.${NC}"
    echo "Please install it following: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    exit 1
fi

echo -e "${GREEN}✓ GPU detected and accessible${NC}"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo ""

# Create outputs directory if it doesn't exist
mkdir -p outputs

# Check if user wants to build or just run
BUILD_FLAG=""
if [ "$1" == "--build" ] || [ "$1" == "-b" ]; then
    echo -e "${YELLOW}Building Docker image...${NC}"
    BUILD_FLAG="--build"
fi

# Run with docker-compose
echo "Starting inference tests..."
echo ""
docker compose up $BUILD_FLAG

# Show results
echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""

# Find and display the latest result file
LATEST_RESULT=$(ls -t outputs/inference_results_*.json 2>/dev/null | head -n 1)

if [ -n "$LATEST_RESULT" ]; then
    echo "Results saved to: $LATEST_RESULT"
    echo ""

    # Check if jq is available for pretty output
    if command -v jq &> /dev/null; then
        echo "Summary:"
        jq '.summary' "$LATEST_RESULT"
    else
        echo "Install 'jq' for formatted output: sudo apt-get install jq"
        echo "Raw summary:"
        grep -A 5 '"summary"' "$LATEST_RESULT"
    fi
else
    echo -e "${YELLOW}No results file found. Check docker logs for errors.${NC}"
fi

echo ""
echo "View detailed results: cat $LATEST_RESULT"
echo "To rebuild image: $0 --build"
