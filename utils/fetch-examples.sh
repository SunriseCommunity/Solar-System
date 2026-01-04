#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Fetching example configuration files...${NC}"

SUNRISE_URL="https://raw.githubusercontent.com/SunriseCommunity/Sunrise/feat/better-telemetry/Sunrise.Server/appsettings.Production.json.example"
# TODO: Update to main branch when it is merged
#SUNRISE_URL="https://raw.githubusercontent.com/SunriseCommunity/Sunrise/refs/heads/master/Sunrise.Server/appsettings.Production.json.example"

SUNRISE_DEST="Sunrise.Config.Production.json.example"

echo -e "${YELLOW}Fetching appsettings.Production.json.example from Sunrise...${NC}"
if curl -f -s -o "$SUNRISE_DEST" "$SUNRISE_URL"; then
    echo -e "${GREEN}✓ Successfully fetched and saved as ${SUNRISE_DEST}${NC}"
else
    echo -e "${RED}✗ Failed to fetch appsettings.Production.json.example from Sunrise${NC}"
    exit 1
fi

echo -e "${GREEN}All files fetched successfully!${NC}"

