# EMCRM - Event Management CRM System

A FastAPI-based CRM system for event management with DynamoDB for storage and OpenSearch for fast querying.

## Architecture

- **Backend**: FastAPI with Pydantic for data validation and settings management
- **Authentication**: Cognito for user authentication and authorization (can be enabled or disabled in local)
- **Database**: Amazon DynamoDB (local with Docker for development, AWS cloud for production)
- **Search**: OpenSearch for fast querying and filtering (local with Docker for development, AWS cloud for production)
- **Deployment**: Docker for local development, Terraform for AWS deployment

## Data Models

The system uses a **single-table design** for DynamoDB with separate email tracking table:

### Core Models

#### User Model
- **Fields**: `id`, `firstName`, `lastName`, `email`, `phoneNumber`, `avatar`, `gender`, `jobTitle`, `company`, `city`, `state`, `attendedCount`, `hostedCount`
- **Validation**: Email validation, string constraints, non-negative counters
- **Storage**: DynamoDB (`PK: user#{id}`, `SK: user#{id}`) + OpenSearch indexing
- **Features**: Automatic attended/hosted count tracking

#### Event Model
- **Fields**: `id`, `slug`, `title`, `description`, `startAt`, `endAt`, `venue`, `maxCapacity`, `owner`, `hosts`
- **Validation**: Date validation (endAt > startAt), slug pattern, capacity constraints
- **Storage**: DynamoDB (`PK: event#{id}`, `SK: event#{id}`)
- **Features**: Multi-host support, capacity management

#### EventAttendance Model
- **Fields**: `user_id`, `event_id`, `attended`, `createdAt`
- **Storage**: DynamoDB (`PK: user#{user_id}`, `SK: event#{event_id}`)
- **Purpose**: Many-to-many relationship between users and events
- **Features**: Automatic user attendance count increment

#### Email System Models

**EmailRequest Model**:
- **Fields**: `email_id`, `filter`, `createdAt`, `totalRecipients`, `status`, `subject`, `body`
- **Storage**: Email table (`PK: email#{email_id}`, `SK: email#{email_id}`)
- **Purpose**: Tracks bulk email campaigns with user filtering

**Email Model**:
- **Fields**: `email_id`, `user_id`, `status`, `createdAt`
- **Storage**: Email table (`PK: req_email#{email_id}`, `SK: user#{user_id}`)
- **Purpose**: Individual email delivery tracking

#### UserFilter Model
- **Fields**: `company`, `jobTitle`, `city`, `state`, `minAttended`, `maxAttended`, `minHosted`, `maxHosted`
- **Purpose**: Advanced user search and email targeting
- **Validation**: Range validation for min/max values

### Database Design

#### Main Table (crm_data)
- **Single-table design** with composite keys
- **Global Secondary Indexes**:
  - `TypeIndex`: Query by entity type (user, event, attendance)
  - `SKIndex`: Reverse lookup capabilities
  - `EmailIndex`: User email lookups
  - `SlugIndex`: Event slug lookups

#### Email Table (email_data)
- **Separate table** for email tracking and analytics
- **Global Secondary Indexes**:
  - `EmailIndex`: Email request lookups
  - `UserIndex`: User-specific email history
  - `TypeIndex`: Email entity type queries

## API Endpoints
Check [API.md](API.md) for detailed endpoint documentation.

## Areas for Improvement

**Performance & Scalability**: Add Redis caching, connection pooling, auto-scaling, and microservices architecture for better performance and horizontal scaling

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

## Testing

See [API_TEST.md](test/API_TEST.md) for comprehensive testing guide using Postman collection.

## Development Log

- **Day 1**: Full data model + DynamoDB + simple test cases
- **Day 2**: OpenSearch integration + large dataset testing (~10,000 users), bug fixes
- **Day 3**: Testing, added `run_in_threadpool`, Docker deployment
- **Day 4**: Cognito integration, AWS connectivity, comprehensive testing
- **Day 5**: Terraform deployment, production testing
- **Day 6**: Custom domain name, SSL certificate, documentation finalization

## AWS Deployment with Terraform

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