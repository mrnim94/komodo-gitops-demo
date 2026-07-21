#!/usr/bin/env bash
# A small real deployment hook for the Komodo Repo resource.
# It publishes a static page through a systemd-managed Python web server.
set -Eeuo pipefail

APP_NAME="komodo-gitops-demo-app"
APP_DIR="/opt/${APP_NAME}"
WEB_ROOT="${APP_DIR}/public"
SERVICE="${APP_NAME}.service"
PORT="8082"
REPO_DIR="$(pwd)"

# Do not steal a port that is already owned by another application.
if ss -ltnH "( sport = :${PORT} )" | grep -q .; then
  if ! systemctl is-active --quiet "$SERVICE"; then
    echo "ERROR: TCP port ${PORT} is already in use and ${SERVICE} is not active." >&2
    exit 1
  fi
fi

install -d -m 0755 "$WEB_ROOT"
commit="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
deployed_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
hostname="$(hostname -f 2>/dev/null || hostname)"

cat > "${WEB_ROOT}/index.html" <<HTML
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Komodo GitOps Demo</title>
<style>body{font-family:system-ui,sans-serif;max-width:720px;margin:4rem auto;padding:0 1rem;background:#111827;color:#e5e7eb}main{border:1px solid #374151;border-radius:12px;padding:2rem}code{color:#86efac}small{color:#9ca3af}</style></head>
<body><main><h1>Komodo GitOps Repo hook works ✅</h1><p>This page was rendered by <code>scripts/deploy.sh</code>, then published by a systemd service.</p>
<ul><li>Host: <code>${hostname}</code></li><li>Git commit: <code>${commit}</code></li><li>Deployed UTC: <code>${deployed_at}</code></li></ul>
<small>Managed by Komodo Resource: komodo-gitops-demo-script-ahihi</small></main></body></html>
HTML

cat > "/etc/systemd/system/${SERVICE}" <<UNIT
[Unit]
Description=Komodo GitOps demo static site
After=network.target

[Service]
Type=simple
WorkingDirectory=${WEB_ROOT}
ExecStart=/usr/bin/python3 -m http.server ${PORT} --bind 0.0.0.0 --directory ${WEB_ROOT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now "$SERVICE"
systemctl is-active --quiet "$SERVICE"

# The page must be reachable through the host networking before a hook succeeds.
curl --fail --silent --show-error "http://127.0.0.1:${PORT}/" | grep -Fq 'Komodo GitOps Repo hook works'
printf 'Deployment succeeded: http://%s:%s/ (commit %s)\n' "$hostname" "$PORT" "$commit"
