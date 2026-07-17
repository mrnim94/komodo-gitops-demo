#!/usr/bin/env bash
set -Eeuo pipefail

echo "Deploy started: $(date -Is)"
echo "Working directory: $(pwd)"

# Ví dụ:
# docker compose -f compose.yaml up -d --remove-orphans
# npm ci
# npm run build

echo "Deploy completed"