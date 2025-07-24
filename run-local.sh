#!/bin/bash

# EMCRM Local Development Runner
# This script demonstrates how to run the application locally with environment files

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${YELLOW}EMCRM Local Development Runner${NC}"
echo "This script runs the EMCRM application locally using Docker with environment files."
echo ""

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if the Docker image exists
if ! docker image inspect emcrm-api &> /dev/null; then
    echo -e "${YELLOW}Docker image 'emcrm-api' not found. Building it now...${NC}"
    docker build -f docker/Dockerfile . -t emcrm-api
fi


ENV_FILE=".env"
echo -e "${GREEN}Using .env for configuration${NC}"


# Run the application
echo -e "\n${GREEN}Starting EMCRM application...${NC}"
echo -e "${GREEN}Environment file: ${ENV_FILE}${NC}"
echo -e "${GREEN}Application will be available at: http://localhost:8080${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the application${NC}"
echo ""

docker run --rm --env-file "$ENV_FILE" -p 8080:8080 emcrm-api