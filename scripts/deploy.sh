#!/usr/bin/env bash
set -Eeuo pipefail

echo "Automation started: $(date -Is)"
echo "Repository directory: $(pwd)"

# Put non-Compose automation here. For example:
# npm ci
# npm run build
# ./scripts/migrate-database.sh
# ./scripts/reload-service.sh
#
# Docker Compose deployment belongs in resources/stacks.toml so Komodo can
# track status, logs, updates, and lifecycle actions for the application.

echo "Automation completed: $(date -Is)"
