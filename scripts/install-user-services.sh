#!/usr/bin/env bash
# Install systemd --user units for Postgres, the game app, and daily DB backups.
# No root required.
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_DIR="${HOME}/.config/systemd/user"
mkdir -p "$UNIT_DIR"
NODE_BIN="$(bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; command -v node')"
NPM_BIN="$(bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; command -v npm')"
NODE_DIR="$(dirname "$NODE_BIN")"
PG_BIN="${HOME}/.local/micromamba/envs/killallmumus-pg/bin"

cat >"${UNIT_DIR}/killallmumus-pg.service" <<EOF
[Unit]
Description=Kill All Mumus PostgreSQL (user-space)
After=default.target

[Service]
Type=forking
Environment=PGDATA=%h/.local/pgdata/killallmumus
Environment=PGPORT=5433
Environment=PATH=${PG_BIN}:/usr/bin:/bin
ExecStart=${APP_ROOT}/scripts/pg-start.sh
ExecStop=${APP_ROOT}/scripts/pg-stop.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat >"${UNIT_DIR}/killallmumus.service" <<EOF
[Unit]
Description=Kill All Mumus game server (Express + Postgres)
After=killallmumus-pg.service
Requires=killallmumus-pg.service

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

cat >"${UNIT_DIR}/killallmumus-db-backup.service" <<EOF
[Unit]
Description=Kill All Mumus daily Postgres backup
After=killallmumus-pg.service

[Service]
Type=oneshot
Environment=PATH=${PG_BIN}:/usr/bin:/bin
EnvironmentFile=-${APP_ROOT}/.env
ExecStart=${APP_ROOT}/scripts/db-backup.sh
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
EOF

cat >"${UNIT_DIR}/killallmumus-db-backup.timer" <<EOF
[Unit]
Description=Run Kill All Mumus DB backup every 24 hours

[Timer]
OnCalendar=*-*-* 03:15:00
Persistent=true
RandomizedDelaySec=300
Unit=killallmumus-db-backup.service

[Install]
WantedBy=timers.target
EOF

chmod +x "${APP_ROOT}/scripts/"*.sh

systemctl --user daemon-reload
systemctl --user enable --now killallmumus-pg.service
systemctl --user enable --now killallmumus.service
systemctl --user enable --now killallmumus-db-backup.timer

# Linger so services survive logout
if command -v loginctl >/dev/null 2>&1; then
  if ! loginctl show-user "$USER" -p Linger 2>/dev/null | grep -q yes; then
    echo "NOTE: enable lingering so services stay up after logout:"
    echo "  sudo loginctl enable-linger $USER"
  fi
fi

echo "✓ user services installed"
systemctl --user --no-pager --full status killallmumus-pg.service killallmumus.service || true
systemctl --user --no-pager list-timers 'killallmumus*' || true
