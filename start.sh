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

prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt (yes/no): " response
        case "$response" in
            [Yy][Ee][Ss]|[Yy]) return 0 ;;
            [Nn][Oo]|[Nn]) return 1 ;;
            *) print_error "Please answer yes or no" ;;
        esac
    done
}

MISSING_FILES=()
MISSING_TOOLS=()

print_info "Checking for required files..."

if [ ! -f ".env" ]; then
    MISSING_FILES+=(".env")
    print_warning ".env file not found"
else
    print_success ".env file exists"
fi

if [ ! -f "Sunrise.Config.Production.json" ]; then
    MISSING_FILES+=("Sunrise.Config.Production.json")
    print_warning "Sunrise.Config.Production.json file not found"
else
    print_success "Sunrise.Config.Production.json file exists"
fi

print_info "Checking for required tools..."

if ! command -v git &> /dev/null; then
    MISSING_TOOLS+=("git")
    print_error "Git is not installed"
    print_info "Please install Git from: https://git-scm.com/"
else
    print_success "Git is installed"
fi

if ! command -v docker &> /dev/null; then
    MISSING_TOOLS+=("docker")
    print_error "Docker is not installed"
    print_info "Please install Docker from: https://www.docker.com/get-started/"
else
    print_success "Docker is installed"
fi

if command -v docker &> /dev/null; then
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available"
        print_info "Please install Docker Compose from: https://www.docker.com/get-started/"
        MISSING_TOOLS+=("docker-compose")
    else
        print_success "Docker Compose is available"
    fi
fi

echo ""

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_warning "Some required files are missing:"
    for file in "${MISSING_FILES[@]}"; do
        echo -e "  ${YELLOW}- $file${NC}"
    done
    echo ""
    
    if [[ " ${MISSING_FILES[@]} " =~ " .env " ]]; then
            print_info "You can create .env by running: cp .env.example .env"
    fi
    
    if [[ " ${MISSING_FILES[@]} " =~ " Sunrise.Config.Production.json " ]]; then
        print_info "You can create Sunrise.Config.Production.json by running: cp Sunrise.Config.Production.json.example Sunrise.Config.Production.json"
    fi
    echo ""
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "Some required tools are missing. Please install them before continuing."
    exit 1
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_error "Please create the missing files before starting the setup."
    exit 1
fi

echo ""
print_info "Do you want to build the setup?"
print_info "Note: You should run this if you updated .env, config, or any other configuration files."
echo ""

if prompt_yes_no "Do you want to build and start the Docker containers?"; then
    print_info "Building and starting Docker containers..."
    docker compose up -d --build || {
        print_error "Failed to build and start Docker containers"
        exit 1
    }
    print_success "Docker containers built and started successfully!"
else
    print_info "Starting Docker containers without rebuild..."
    docker compose up -d || {
        print_error "Failed to start Docker containers"
        exit 1
    }
    print_success "Docker containers started successfully!"
fi
