#!/usr/bin/env bash
# Start the user-space PostgreSQL cluster for killallmumus.
set -euo pipefail
export PATH="${HOME}/.local/micromamba/envs/killallmumus-pg/bin:${HOME}/.local/bin:${PATH}"
export PGDATA="${PGDATA:-${HOME}/.local/pgdata/killallmumus}"
PORT="${PGPORT:-5433}"

if pg_isready -h 127.0.0.1 -p "$PORT" >/dev/null 2>&1; then
  echo "PostgreSQL already accepting connections on :$PORT"
  exit 0
fi

mkdir -p "$PGDATA"
if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
  echo "PGDATA not initialized: $PGDATA" >&2
  exit 1
fi

pg_ctl -D "$PGDATA" -l "$PGDATA/postgres.log" start -o "-p $PORT -h 127.0.0.1"
for i in $(seq 1 30); do
  if pg_isready -h 127.0.0.1 -p "$PORT" >/dev/null 2>&1; then
    echo "PostgreSQL ready on 127.0.0.1:$PORT"
    exit 0
  fi
  sleep 0.3
done
echo "PostgreSQL failed to become ready" >&2
exit 1
