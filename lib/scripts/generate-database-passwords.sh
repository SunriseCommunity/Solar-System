#!/bin/bash

NEW_TOKEN_SUNRISE_MYSQL=$(openssl rand -hex 32)

if grep -q '^SUNRISE_MYSQL_PASSWORD=' .env; then
  tmp=$(mktemp)
  sed "s/^SUNRISE_MYSQL_PASSWORD=.*/SUNRISE_MYSQL_PASSWORD=$NEW_TOKEN_SUNRISE_MYSQL/" .env > "$tmp"
  mv "$tmp" .env
else
  echo "SUNRISE_MYSQL_PASSWORD=$NEW_TOKEN_SUNRISE_MYSQL" >> .env
fi

NEW_TOKEN_OBSERVATORY_POSTGRES=$(openssl rand -hex 32)

if grep -q '^OBSERVATORY_POSTGRES_PASSWORD=' .env; then
  tmp=$(mktemp)
  sed "s/^OBSERVATORY_POSTGRES_PASSWORD=.*/OBSERVATORY_POSTGRES_PASSWORD=$NEW_TOKEN_OBSERVATORY_POSTGRES/" .env > "$tmp"
  mv "$tmp" .env
else
  echo "OBSERVATORY_POSTGRES_PASSWORD=$NEW_TOKEN_OBSERVATORY_POSTGRES" >> .env
fi