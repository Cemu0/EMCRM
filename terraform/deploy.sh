#!/bin/bash

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${YELLOW}EMCRM AWS Deployment Script${NC}"
echo "This script will deploy the EMCRM application to AWS using Terraform."
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed. Please install Terraform first.${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install AWS CLI first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}Warning: terraform.tfvars not found. Creating from example file...${NC}"
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${YELLOW}Please edit terraform.tfvars with your AWS configuration before continuing.${NC}"
        exit 1
    else
        echo -e "${RED}Error: terraform.tfvars.example not found. Please create terraform.tfvars manually.${NC}"
        exit 1
    fi
fi

# Initialize Terraform
echo -e "\n${GREEN}Initializing Terraform...${NC}"
terraform init

# Plan the deployment
echo -e "\n${GREEN}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "\n${YELLOW}Do you want to apply the Terraform plan? (y/n)${NC}"
read -r answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Apply the Terraform plan
echo -e "\n${GREEN}Applying Terraform plan...${NC}"
terraform apply tfplan

# Get the ECR repository URL
echo -e "\n${GREEN}Getting ECR repository URL...${NC}"
ECR_REPO=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

# Build the Docker image (using Terraform-specific .dockerignore for security)
echo -e "\n${GREEN}Building Docker image for production deployment...${NC}"
cd ..
# Backup original .dockerignore and use Terraform-specific one
if [ -f "docker/.dockerignore" ]; then
    cp docker/.dockerignore docker/.dockerignore.backup
fi
cp terraform/.dockerignore docker/.dockerignore
docker build -t emcrm-app:latest -f docker/Dockerfile .
# Restore original .dockerignore
if [ -f "docker/.dockerignore.backup" ]; then
    mv docker/.dockerignore.backup docker/.dockerignore
else
    rm docker/.dockerignore
fi

# Log in to ECR
echo -e "\n${GREEN}Logging in to ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO"

# Tag and push the image
echo -e "\n${GREEN}Tagging and pushing Docker image to ECR...${NC}"
docker tag emcrm-app:latest "$ECR_REPO:latest"
docker push "$ECR_REPO:latest"

# Force a new deployment of the ECS service
echo -e "\n${GREEN}Forcing a new deployment of the ECS service...${NC}"
aws ecs update-service --cluster emcrm-cluster --service emcrm-service --force-new-deployment --region "$AWS_REGION"

# Get the load balancer DNS name
echo -e "\n${GREEN}Getting load balancer DNS name...${NC}"
cd terraform
LB_DNS=$(terraform output -raw load_balancer_dns)

echo -e "\n${GREEN}Deployment complete!${NC}"
echo -e "You can access the application at: http://$LB_DNS"
echo -e "It may take a few minutes for the application to become available."