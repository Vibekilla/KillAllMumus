#!/usr/bin/env bash
# Install systemd --user unit for the DEV game server (/var/www/dev, PORT=3001).
# Live remains killallmumus.service on /var/www/killallmumus.com:3000.
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_DIR="${HOME}/.config/systemd/user"
mkdir -p "$UNIT_DIR"

NODE_BIN="$(bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; command -v node')"
NODE_DIR="$(dirname "$NODE_BIN")"
PG_BIN="${HOME}/.local/micromamba/envs/killallmumus-pg/bin"

if [[ ! -f "${APP_ROOT}/.env" ]]; then
  echo "Missing ${APP_ROOT}/.env — copy from live and set PORT=3001 PUBLIC_ORIGIN=https://dev.killallmumus.com" >&2
  exit 1
fi

# Guard: dev must not steal live port
if grep -qE '^PORT=3000\s*$' "${APP_ROOT}/.env" 2>/dev/null; then
  echo "ERROR: ${APP_ROOT}/.env has PORT=3000 — refuse to start (would collide with live)." >&2
  echo "  Set PORT=3001 for the dev service." >&2
  exit 1
fi

cat >"${UNIT_DIR}/killallmumus-dev.service" <<EOF
[Unit]
Description=Kill All Mumus DEV server (Express — branch dev @ ${APP_ROOT})
After=killallmumus-pg.service
Wants=killallmumus-pg.service

[Service]
Type=simple
WorkingDirectory=${APP_ROOT}
Environment=NODE_ENV=production
Environment=PATH=${NODE_DIR}:${PG_BIN}:/usr/bin:/bin
EnvironmentFile=-${APP_ROOT}/.env
ExecStart=${NODE_BIN} ${APP_ROOT}/server.js
Restart=on-failure
RestartSec=3
KillMode=mixed

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now killallmumus-dev.service

echo "✓ killallmumus-dev.service installed"
systemctl --user --no-pager --full status killallmumus-dev.service || true

for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:3001/api/health 2>/dev/null | grep -q '"ok":true'; then
    curl -fsS http://127.0.0.1:3001/api/health
    echo
    echo "✓ dev health OK on :3001"
    exit 0
  fi
  sleep 0.5
done
echo "WARN: health check on :3001 not green yet" >&2
exit 0
