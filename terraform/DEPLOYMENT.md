# EMCRM Deployment Guide

This guide explains how to deploy the EMCRM application to AWS using the automated deployment script.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (version 1.0.0 or later)
2. [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials
3. [Docker](https://docs.docker.com/get-docker/) installed for building the application image

Because Default ALB DNS Names Don't Support HTTPS, I will use a Custom Domain Name and SSL Certificate, (I didn't purchage a DNS on Route 53, so I will use a subdomain of my existing domain)


## Quick Deployment

### 1. Configure Your Environment

Copy and customize the Terraform variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to set your AWS region and other configuration options. The deployment script will automatically create a VPC if needed.

### 2. Deploy Everything

Run the automated deployment script:

```bash
./deploy.sh
```

This script will:
- Initialize Terraform
- Plan and apply the infrastructure
- Build and push the Docker image to ECR
- Deploy the application to ECS
- Provide you with the application URL

### 3. Access Your Application

After deployment completes, the script will display the load balancer URL where you can access your application.

## when access on first time, there is no user created for the cognito
you need to create a user for cognito, then you can access the application, navigate to the cognito user pool, create a user, and set the password.

then you can login with URL: https://<your-domain>/auth/login
after success login, you can access the document of the API with URL: https://<your-domain>/docs

## Cleaning Up

To destroy the infrastructure when you're done:

```bash
terraform destroy
```

Note: you might need to run twice