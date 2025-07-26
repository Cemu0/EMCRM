#!/bin/bash

# EMCRM Development Environment Manager
# This script helps manage the Docker development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_COMPOSE_FILE="docker/docker-compose.dev.yml"
ENV_FILE=".env"
ENV_TEMPLATE=".env.dev"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Setup environment file
setup_env() {
    if [ ! -f "$ENV_FILE" ]; then
        log_info "Creating .env file from template..."
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log_success "Created $ENV_FILE from $ENV_TEMPLATE"
        log_warning "Please review and modify $ENV_FILE as needed"
    else
        log_info "Environment file $ENV_FILE already exists"
    fi
}

# Start development environment
start_dev() {
    log_info "Starting EMCRM development environment..."
    check_docker
    setup_env
    
    docker compose -f "$DOCKER_COMPOSE_FILE" up --build -d 
    
    log_success "Development environment started!"
    log_info "Services available at:"
    echo "  - API: http://localhost:8080"
    echo "  - DynamoDB Local: http://localhost:8000"
    echo "  - OpenSearch: http://localhost:9200"
    echo "  - OpenSearch Dashboards: http://localhost:5601"
    echo ""
    log_info "Use 'docker compose -f $DOCKER_COMPOSE_FILE logs -f api' to view API logs"
}

# Stop development environment
stop_dev() {
    log_info "Stopping EMCRM development environment..."
    docker compose -f "$DOCKER_COMPOSE_FILE" down
    log_success "Development environment stopped!"
}

# Restart development environment
restart_dev() {
    log_info "Restarting EMCRM development environment..."
    stop_dev
    start_dev
}

# Show logs
show_logs() {
    local service=${1:-"api"}
    log_info "Showing logs for service: $service"
    docker compose -f "$DOCKER_COMPOSE_FILE" logs -f "$service"
}

# Show status
show_status() {
    log_info "Development environment status:"
    docker compose -f "$DOCKER_COMPOSE_FILE" ps
}

# Clean up (remove containers and volumes)
clean() {
    log_warning "This will remove all containers and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Cleaning up development environment..."
        docker compose -f "$DOCKER_COMPOSE_FILE" down -v --remove-orphans
        docker system prune -f
        log_success "Cleanup completed!"
    else
        log_info "Cleanup cancelled."
    fi
}

# Run tests
run_tests() {
    log_info "Running tests in development environment..."
    docker compose -f "$DOCKER_COMPOSE_FILE" exec api python -m pytest test/ -v
}

# Run generate
run_generate() {
    log_info "Running generate in development environment..."
    docker compose -f "$DOCKER_COMPOSE_FILE" exec api python -m pytest test/generate_users_events.py -s
}

# Show help
show_help() {
    echo "EMCRM Development Environment Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start the development environment"
    echo "  stop      Stop the development environment"
    echo "  restart   Restart the development environment"
    echo "  status    Show status of all services"
    echo "  logs      Show logs (default: api service)"
    echo "  logs [service]  Show logs for specific service"
    echo "  test      Run tests"
    echo "  generate  Generate test data"
    echo "  clean     Clean up containers and volumes"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs api"
}

# Main script logic
case "${1:-help}" in
    start)
        start_dev
        ;;
    stop)
        stop_dev
        ;;
    restart)
        restart_dev
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    test)
        run_tests
        ;;
    generate)
        run_generate
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac