#!/bin/bash

NEW_TOKEN=$(openssl rand -hex 32)

if grep -q '^OBSERVATORY_IGNORE_RATELIMIT_KEY=' .env; then
  tmp=$(mktemp)
  sed "s/^OBSERVATORY_IGNORE_RATELIMIT_KEY=.*/OBSERVATORY_IGNORE_RATELIMIT_KEY=$NEW_TOKEN/" .env > "$tmp"
  mv "$tmp" .env
else
  echo "OBSERVATORY_IGNORE_RATELIMIT_KEY=$NEW_TOKEN" >> .env
fi
