#!/bin/bash

COMPOSE_FILE="docker-compose.local.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/scripts/update-common.sh"
