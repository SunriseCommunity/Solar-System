#!/bin/bash

NEW_TOKEN=$(openssl rand -hex 32)

if grep -q '^SUNRISE_API_TOKEN_SECRET=' .env; then
  sed -i "s/^SUNRISE_API_TOKEN_SECRET=.*/SUNRISE_API_TOKEN_SECRET=$NEW_TOKEN/" .env
else
  echo "SUNRISE_API_TOKEN_SECRET=$NEW_TOKEN" >> .env
fi
