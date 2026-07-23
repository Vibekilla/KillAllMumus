#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/micromamba/envs/killallmumus-pg/bin:${HOME}/.local/bin:${PATH}"
export PGDATA="${PGDATA:-${HOME}/.local/pgdata/killallmumus}"
PORT="${PGPORT:-5433}"

if ! pg_isready -h 127.0.0.1 -p "$PORT" >/dev/null 2>&1; then
  echo "PostgreSQL not running on :$PORT"
  exit 0
fi
pg_ctl -D "$PGDATA" stop -m fast
echo "PostgreSQL stopped"
