# EMCRM - Event Management CRM System

A FastAPI-based CRM system for event management with DynamoDB for storage and OpenSearch for fast querying.

## Architecture

- **Backend**: FastAPI with Pydantic for data validation and settings management
- **Database**: Amazon DynamoDB (local with Docker for development, AWS cloud for production)
- **Search**: OpenSearch for fast querying and filtering
- **Deployment**: Docker for local development, Terraform for AWS deployment


# Data Models ( API documentation for detail)
models.py -> keep simple for demo purpose
there is additional EventAttendance table for attentdance in main table (Single table mode)
Email table for tracking status

# places for improvement based on product requirement:
add history for event edit/EventUpdate 


## Development

### Quick Start with Docker (Recommended)

For the best development experience, use the Docker development environment:

```bash
# Start the complete development environment
./dev.sh start

# View API documentation
open http://localhost:8080/docs

# View logs
./dev.sh logs

# Run tests
./dev.sh test

# Stop the environment
./dev.sh stop
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development environment documentation.

### Manual Local Development

If you prefer to run without Docker:

```bash
# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.dev .env

# Start the API server
uvicorn app.main:app --reload

# Run tests
python -m pytest test/test_crm.py

# Run specific test
python -m pytest test/test_crm.py -k test_duplicate_email_should_fail -s

# Create large user dataset
python -m pytest stress_test/rand_users.py -s
```

**Note**: Manual development requires setting up DynamoDB Local and OpenSearch separately.

### Test coverage

python -m pytest test/test_crm.py --cov=app --cov-report=term-missing
    
===================================================================================================== tests coverage 
Name                           Stmts   Miss  Cover   Missing
------------------------------------------------------------
app/__init__.py                    0      0   100%
app/db/init.py                    34      9    74%   74-75, 108-109, 128-132, 140
app/db/session.py                 13      4    69%   19-20, 24-25
app/main.py                       17      4    76%   12-16
app/models.py                    110     11    90%   83-85, 134-137, 142-145
app/opensearch/client.py           9      3    67%   8-13
app/query/filter_users.py         92     26    72%   29, 35-36, 43, 49, 59, 67, 74-86, 104, 122, 124, 126, 133, 141, 161-162
app/routes/attendance.py          30      7    77%   35-40, 53-59
app/routes/email.py               56     21    62%   20, 54-59, 65-81, 85-101
app/routes/events.py              58      1    98%   94
app/routes/users.py               59      4    93%   16, 77, 108-109
app/services/email_sender.py       2      0   100%
------------------------------------------------------------
TOTAL                            480     90    81%


# LOGS
day 1: full datamodel + dynamodb + simple test case
day 2: open search + test large case (~10000 user), fix minor bugs
day 3: test, add run_in_threadpool, deploy docker
day 4: connect to AWS, test again...


### Docker Commands

```bash
# Build production image
docker build -f docker/Dockerfile . -t emcrm-api

# Run production container
docker run -p 8080:8080 emcrm-api

# Run tests in production environment
docker compose -f docker/docker-compose.yml run --rm api python -m pytest test/test_crm.py

# Start production environment
docker compose -f docker/docker-compose.yml up
```



## Configuration

The application uses Pydantic's BaseSettings for configuration management. All configuration settings are centralized in `app/config.py` and can be overridden using environment variables or a `.env` file.

A template environment file is provided at `template.env`. Copy this file to `.env` and customize the values as needed:

```bash
cp template.env .env
```

## Deployment

### Local Development

For local development, use the development environment:

```bash
./dev.sh start
```

### Local Production Testing

To test the production Docker setup locally:

```bash
docker compose -f docker/docker-compose.yml up
```

### AWS Deployment with Terraform

The application can be deployed to AWS using Terraform. See the [Deployment Guide](terraform/DEPLOYMENT.md) for detailed instructions.

```bash
cd terraform
terraform init
terraform apply
```

This will create the following AWS resources:

- DynamoDB tables for storing CRM and email data
- ECR repository for the Docker image
- ECS cluster, task definition, and service for running the application
- Application Load Balancer for routing traffic
- OpenSearch domain for search functionality with advanced configuration options:
  - Cluster configuration with optional dedicated master and warm nodes
  - VPC deployment option for enhanced security
  - Auto-Tune for performance optimization
  - CloudWatch log integration
  - Optional Cognito authentication for OpenSearch Dashboard
- IAM roles and policies for secure access
- CloudWatch log group for logging
- Secrets Manager for storing sensitive information