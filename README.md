# EMCRM - Event Management CRM System

A FastAPI-based CRM system for event management with DynamoDB for storage and OpenSearch for fast querying.

## Architecture

- **Backend**: FastAPI with Pydantic for data validation and settings management
- **Authentication**: Cognito for user authentication and authorization (can be enable or disable in local)
- **Database**: Amazon DynamoDB (local with Docker for development, AWS cloud for production)
- **Search**: OpenSearch for fast querying and filtering (local with Docker for development, AWS cloud for production)
- **Deployment**: Docker for local development, Terraform for AWS deployment


# Data Models ( API documentation (auto generated) for detail)
models.py -> keep simple for demo purpose
there is additional EventAttendance table for attentdance in main table (Single table mode)
Email table for tracking status

# places for improvement based on product requirement:
- add history for event edit/EventUpdate 


## Development

### Quick Start with Docker (Recommended)

For the best development experience, use the Docker development environment:

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
python -m pytest test/generate_users_events.py -s

# Run tests with coverage
python -m pytest test/test_crm.py --cov=app --cov-report=term-missing
```

**Note**: Manual development requires setting up DynamoDB Local and OpenSearch separately.


# LOGS
day 1: full datamodel + dynamodb + simple test case
day 2: open search + test large case (~10000 user), fix minor bugs
day 3: test, add run_in_threadpool, deploy docker
day 4: add cognito, connect to AWS, test again...
day 5: deploy terraform, test
day 6: add custom domain name and ssl certificate, finalize documentation


### AWS Deployment with Terraform

The application can be deployed to AWS using Terraform. See the [Deployment Guide](terraform/DEPLOYMENT.md) for detailed instructions.

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
- Route 53 record for custom domain name (if required)