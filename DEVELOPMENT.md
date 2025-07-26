# EMCRM Development Environment

This guide will help you set up and run the EMCRM application in a local development environment using Docker.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- Git
- At least 4GB of available RAM

## Quick Start

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone <repository-url>
   cd EMCRM
   ```

2. **Start the development environment**:
   ```bash
   ./dev.sh start
   ```

3. **Access the services**:
   - **API**: http://localhost:8080
   - **API Documentation**: http://localhost:8080/docs
   - **DynamoDB Local**: http://localhost:8000
   - **OpenSearch**: http://localhost:9200
   - **OpenSearch Dashboards**: http://localhost:5601

4. **(Optional)**  
when use authenticate, you need to create a user for cognito, then you can access the application, navigate to the cognito user pool, create a user, and set the password.

then you can login with URL: https://your-domain/auth/login otherwhise you will get error on login.
after success login, you can access the document of the API with URL: https://your-domain/docs

## Development Script Usage

The `dev.sh` script provides convenient commands to manage your development environment:

```bash
# Start all services
./dev.sh start

# Stop all services
./dev.sh stop

# Restart all services
./dev.sh restart

# View service status
./dev.sh status

# View API logs (real-time)
./dev.sh logs

# View logs for a specific service
./dev.sh logs opensearch-node1
./dev.sh logs dynamodb-local

# Run tests
./dev.sh test

# Initialize database tables
./dev.sh init-db

# Clean up (remove containers and volumes)
./dev.sh clean

# Show help
./dev.sh help
```

## Development Features

### Hot Reloading
The development environment is configured with hot reloading enabled. Any changes you make to the Python code in the `app/` directory will automatically restart the API server.

### Volume Mounts
- Source code is mounted as read-only volumes for hot reloading
- Environment file (`.env`) is mounted if it exists
- OpenSearch data is persisted in a named volume

### Development Tools
The development Docker image includes additional tools:
- `ipython` for interactive Python sessions
- `pytest-asyncio` for async testing
- `watchfiles` for file watching
- `vim` and `git` for basic editing and version control

## Environment Configuration

### Environment File Setup
When you first run `./dev.sh start`, it will automatically create a `.env` file from the `.env.dev` template if one doesn't exist.

You can customize your environment by editing the `.env` file:

```bash
# Copy the development template
cp .env.dev .env

# Edit as needed
vim .env
```

### Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_DEBUG` | `true` | Enable debug mode |
| `APP_LOG_LEVEL` | `DEBUG` | Logging level |
| `DB_DYNAMODB_ENDPOINT` | `http://localhost:8000` | DynamoDB endpoint |
| `OPENSEARCH_ENDPOINT` | `http://localhost:9200` | OpenSearch endpoint |

## Services Overview

### API Service (`emcrm-api-dev`)
- **Port**: 8080
- **Features**: Hot reloading, debug logging
- **Health Check**: http://localhost:8080/health

### DynamoDB Local (`dynamodb-local-dev`)
- **Port**: 8000
- **Mode**: In-memory with shared database
- **Web Shell**: http://localhost:8000/shell

### OpenSearch (`opensearch-node1-dev`)
- **Ports**: 9200 (API), 9600 (Performance Analyzer)
- **Mode**: Single-node cluster
- **Security**: Disabled for development

### OpenSearch Dashboards (`opensearch-dashboards-dev`)
- **Port**: 5601
- **Features**: Data visualization and management

## Development Workflow

### Making Code Changes
1. Edit files in the `app/` directory
2. The API server will automatically reload
3. Check logs with `./dev.sh logs`

### Running Tests
```bash
# Run all tests
./dev.sh test

# Run tests manually in container
docker compose -f docker/docker-compose.dev.yml exec api python -m pytest test/ -v

# Run specific test file
docker compose -f docker/docker-compose.dev.yml exec api python -m pytest test/test_crm.py -v
```

### Database Operations
```bash
# Initialize database tables
./dev.sh init-db

# Access DynamoDB shell
open http://localhost:8000/shell

# Run database scripts
docker compose -f docker/docker-compose.dev.yml exec api python test/generate_users_events.py
```

### Debugging
```bash
# View real-time API logs
./dev.sh logs

# Access container shell
docker compose -f docker/docker-compose.dev.yml exec api bash

# Run interactive Python session
docker compose -f docker/docker-compose.dev.yml exec api ipython
```

## Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   # Check what's using the ports
   lsof -i :8080
   lsof -i :8000
   lsof -i :9200
   ```

2. **Docker out of space**:
   ```bash
   # Clean up Docker system
   ./dev.sh clean
   docker system prune -a
   ```

3. **Services not starting**:
   ```bash
   # Check service status
   ./dev.sh status
   
   # View logs for specific service
   ./dev.sh logs dynamodb-local
   ./dev.sh logs opensearch-node1
   ```

4. **Hot reloading not working**:
   - Ensure your code changes are in the `app/` directory
   - Check that the volume mounts are working: `./dev.sh logs`
   - Restart the environment: `./dev.sh restart`

### Performance Tips

1. **Allocate sufficient resources to Docker**:
   - Minimum 4GB RAM
   - 2+ CPU cores recommended

2. **Use Docker Desktop's file sharing optimization**:
   - Enable "Use gRPC FUSE for file sharing" in Docker Desktop settings

3. **Exclude unnecessary files**:
   - The `.dockerignore` file is configured to exclude common unnecessary files

## Production Differences

The development environment differs from production in several ways:

- **Security**: OpenSearch security is disabled
- **Persistence**: DynamoDB runs in-memory mode
- **Logging**: Debug level logging is enabled
- **Hot Reloading**: Enabled for faster development
- **Additional Tools**: Development tools are included in the image

## Next Steps

- Review the API documentation at http://localhost:8080/docs
- Explore the codebase in the `app/` directory
- Run the test suite to understand the application behavior
- Check out the main README.md for more information about the project