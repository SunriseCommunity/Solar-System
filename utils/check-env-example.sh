#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SILENCED_KEYS=(
    "SUNRISE_WEB_DOMAIN"
    "OBSERVATORY_API_TOKEN_SECRET"
    "SUNRISE_OBSERVATORY_API_KEY"
)

SUNRISE_ENV="Sunrise/.env.example"
OBSERVATORY_ENV="Observatory/.env.example"

ROOT_ENV=".env.example"

extract_keys() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo ""
        return
    fi
    
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$file" | cut -d'=' -f1 | sort -u
}

is_silenced() {
    local key="$1"
    for silenced in "${SILENCED_KEYS[@]}"; do
        if [ "$key" == "$silenced" ]; then
            return 0
        fi
    done
    return 1
}

echo -e "${GREEN}Checking .env.example files...${NC}"

if [ ! -f "$SUNRISE_ENV" ]; then
    echo -e "${YELLOW}⚠ Warning: $SUNRISE_ENV not found${NC}"
fi

if [ ! -f "$OBSERVATORY_ENV" ]; then
    echo -e "${YELLOW}⚠ Warning: $OBSERVATORY_ENV not found${NC}"
fi

SUNRISE_KEYS=$(extract_keys "$SUNRISE_ENV" | sed 's/^/SUNRISE_/')
OBSERVATORY_KEYS=$(extract_keys "$OBSERVATORY_ENV" | sed 's/^/OBSERVATORY_/')

ALL_SOURCE_KEYS=$(echo -e "$SUNRISE_KEYS\n$OBSERVATORY_KEYS" | sort -u)

if [ ! -f "$ROOT_ENV" ]; then
    echo -e "${YELLOW}⚠ Warning: $ROOT_ENV not found. Creating it...${NC}"
    touch "$ROOT_ENV"
fi

ROOT_KEYS=$(extract_keys "$ROOT_ENV")

MISSING_KEYS=()
while IFS= read -r key; do
    if [ -z "$key" ]; then
        continue
    fi
    
    if is_silenced "$key"; then
        continue
    fi
    
    if ! echo "$ROOT_KEYS" | grep -q "^${key}$"; then
        MISSING_KEYS+=("$key")
    fi
done <<< "$ALL_SOURCE_KEYS"

if [ ${#MISSING_KEYS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All keys are present in $ROOT_ENV${NC}"
    exit 0
else
    echo -e "${RED}✗ Missing keys in $ROOT_ENV:${NC}"
    for key in "${MISSING_KEYS[@]}"; do
        echo -e "${RED}  - $key${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}To fix this, add the missing keys to $ROOT_ENV${NC}"
    exit 1
fi

