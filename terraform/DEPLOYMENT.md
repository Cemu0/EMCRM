# EMCRM Deployment Guide

This guide explains how to deploy the EMCRM application to AWS using Terraform.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (version 1.0.0 or later)
2. [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials
3. [Docker](https://docs.docker.com/get-docker/) installed for building the application image

## Configuration

1. Copy the example Terraform variables file and customize it for your environment:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` to set your AWS VPC, subnet IDs, and other configuration options.

## Building the Docker Image

1. Build the Docker image locally:

```bash
docker build -t emcrm-app:latest -f docker/Dockerfile .
```

2. After applying Terraform (see next section), push the image to the created ECR repository:

```bash
# Get the ECR repository URL from Terraform output
ECR_REPO=$(terraform -chdir=terraform output -raw ecr_repository_url)

# Log in to ECR
aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin $ECR_REPO

# Tag and push the image
docker tag emcrm-app:latest $ECR_REPO:latest
docker push $ECR_REPO:latest
```

## Deploying with Terraform

1. Initialize Terraform:

```bash
cd terraform
terraform init
```

2. Plan the deployment to verify the changes:

```bash
terraform plan
```

3. Apply the Terraform configuration to create the infrastructure:

```bash
terraform apply
```

4. After the infrastructure is created, push the Docker image to ECR as described in the previous section.

5. The application will be deployed automatically once the image is pushed to ECR.

## Accessing the Application

After deployment, you can access the application using the load balancer DNS name:

```bash
terraform output load_balancer_dns
```

This will output the DNS name of the load balancer, which you can use to access the application.

## OpenSearch Configuration and Dashboard

### OpenSearch Configuration Options

The Terraform configuration includes several options for customizing your OpenSearch deployment:

#### Basic Configuration
- `opensearch_domain_name`: Name of the OpenSearch domain (default: "emcrm")
- `opensearch_engine_version`: Version of OpenSearch to deploy (default: "OpenSearch_2.11")
- `opensearch_host`: Host of an existing OpenSearch domain (leave empty to create a new domain)

#### Cluster Configuration
- `opensearch_instance_type`: Instance type for OpenSearch nodes (default: "t3.small.search")
- `opensearch_instance_count`: Number of instances in the cluster (default: 1)
- `opensearch_vpc_enabled`: Whether to deploy OpenSearch within a VPC (default: false)

#### Advanced Cluster Options
- `opensearch_dedicated_master_enabled`: Whether to use dedicated master nodes (default: false)
- `opensearch_dedicated_master_count`: Number of dedicated master nodes (default: 3)
- `opensearch_dedicated_master_type`: Instance type for dedicated master nodes (default: "t3.small.search")
- `opensearch_warm_enabled`: Whether to use warm nodes for cost optimization (default: false)
- `opensearch_warm_count`: Number of warm nodes (default: 2)
- `opensearch_warm_type`: Instance type for warm nodes (default: "ultrawarm1.medium.search")

#### Storage Configuration
- `opensearch_volume_type`: EBS volume type (default: "gp3")
- `opensearch_volume_size`: EBS volume size in GB (default: 10)
- `opensearch_volume_iops`: IOPS for gp3/io1 volumes (default: 3000)

#### Security and Access
- `opensearch_allowed_cidr_blocks`: CIDR blocks allowed to access OpenSearch (default: ["0.0.0.0/0"])
- `opensearch_cognito_enabled`: Whether to enable Cognito authentication for OpenSearch Dashboard (default: false)

#### Performance and Monitoring
- `opensearch_auto_tune_enabled`: Whether to enable Auto-Tune (default: true)
- `opensearch_log_publishing_enabled`: Whether to publish logs to CloudWatch (default: true)

#### Custom Endpoint
- `opensearch_custom_endpoint_enabled`: Whether to use a custom endpoint (default: false)
- `opensearch_custom_endpoint`: Custom endpoint domain name (e.g., "search.example.com")
- `opensearch_custom_endpoint_certificate_arn`: ARN of the ACM certificate for the custom endpoint

### Accessing OpenSearch Dashboard

If you've deployed a new OpenSearch domain, you can access the OpenSearch Dashboard using the OpenSearch endpoint:

```bash
terraform output opensearch_endpoint
```

The OpenSearch Dashboard will be available at `https://<opensearch_endpoint>/_dashboards/`.

#### Authentication

- **Standard Authentication**: Use the master username and password specified in your terraform.tfvars file.
- **Cognito Authentication**: If you've enabled Cognito authentication (`opensearch_cognito_enabled = true`), you'll be redirected to the Cognito login page.

## Updating the Application

To update the application:

1. Build a new Docker image with your changes
2. Push the new image to ECR with the same tag (latest)
3. Force a new deployment of the ECS service:

```bash
aws ecs update-service --cluster emcrm-cluster --service emcrm-service --force-new-deployment
```

## Cleaning Up

To destroy the infrastructure when you're done:

```bash
terraform destroy
```

## Environment Variables

The application uses the following environment variables, which are set in the ECS task definition:

### Database Configuration
- `DB_AWS_REGION`: AWS region for DynamoDB
- `DB_MAIN_TABLE_NAME`: Name of the main DynamoDB table
- `DB_EMAIL_TABLE_NAME`: Name of the email DynamoDB table

### OpenSearch Configuration
- `OPENSEARCH_MODE`: Set to "cloud" for AWS deployment
- `OPENSEARCH_HOST`: Host of the OpenSearch domain
- `OPENSEARCH_USERNAME`: Username for OpenSearch (stored in Secrets Manager)
- `OPENSEARCH_PASSWORD`: Password for OpenSearch (stored in Secrets Manager)
- `OPENSEARCH_PORT`: Port for OpenSearch (default: 443)
- `OPENSEARCH_USE_SSL`: Whether to use SSL for OpenSearch connections (default: true)
- `OPENSEARCH_VERIFY_CERTS`: Whether to verify SSL certificates (default: true)
- `OPENSEARCH_CA_CERTS`: Path to CA certificates file (if using custom CA)

### Application Configuration
- `APP_NAME`: Application name
- `APP_DEBUG`: Debug mode (set to "false" for production)
- `APP_LOG_LEVEL`: Logging level
- `APP_PORT`: Port on which the application listens (default: 8080)
- `APP_HOST`: Host on which the application listens (default: 0.0.0.0)

## Troubleshooting

### Checking Logs

You can check the application logs in CloudWatch:

```bash
aws logs get-log-events --log-group-name /ecs/emcrm --log-stream-name <log-stream-name>
```

Replace `<log-stream-name>` with the actual log stream name, which you can find in the CloudWatch console.

### Checking ECS Service Status

```bash
aws ecs describe-services --cluster emcrm-cluster --services emcrm-service
```

### Connecting to the Container

You can use the AWS ECS Exec feature to connect to a running container for debugging:

```bash
aws ecs execute-command --cluster emcrm-cluster --task <task-id> --container emcrm-app --interactive --command "/bin/bash"
```

Replace `<task-id>` with the actual task ID, which you can find using:

```bash
aws ecs list-tasks --cluster emcrm-cluster
```