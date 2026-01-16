#!/bin/bash

NEW_TOKEN=$(openssl rand -hex 32)

if grep -q '^SUNRISE_API_TOKEN_SECRET=' .env; then
  tmp=$(mktemp)
  sed "s/^SUNRISE_API_TOKEN_SECRET=.*/SUNRISE_API_TOKEN_SECRET=$NEW_TOKEN/" .env > "$tmp"
  mv "$tmp" .env
else
  echo "SUNRISE_API_TOKEN_SECRET=$NEW_TOKEN" >> .env
fi
