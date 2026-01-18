#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

detect_docker_compose() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null && docker-compose version &> /dev/null; then
        echo "docker-compose"
    else
        echo ""
    fi
}

run_docker_compose() {
    if [[ "$DOCKER_COMPOSE_CMD" == "docker compose" ]]; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

MISSING_TOOLS=()

print_info "Checking for required tools..."

if ! command -v docker &> /dev/null; then
    MISSING_TOOLS+=("docker")
    print_error "Docker is not installed"
    print_info "Please install Docker from: https://www.docker.com/get-started/"
else
    print_success "Docker is installed"
fi

DOCKER_COMPOSE_CMD=""
if command -v docker &> /dev/null; then
    DOCKER_COMPOSE_CMD=$(detect_docker_compose)
    if [ -z "$DOCKER_COMPOSE_CMD" ]; then
        print_error "Docker Compose is not available"
        print_info "Please install Docker Compose from: https://www.docker.com/get-started/"
        MISSING_TOOLS+=("docker-compose")
    else
        print_success "Docker Compose is available ($DOCKER_COMPOSE_CMD)"
    fi
fi

echo ""

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "Some required tools are missing. Please install them before continuing."
    exit 1
fi

print_info "Stopping Docker containers..."
run_docker_compose stop || {
    print_error "Failed to stop Docker containers"
    exit 1
}
print_success "Docker containers stopped successfully!"
