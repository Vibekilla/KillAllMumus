#!/usr/bin/env bash
# Daily Postgres backup with storage-runway contingencies.
#
# Backups land in the parent directory of this project:
#   /home/vibekilla/.grok/worktrees/www-killallmumuscom/db-backups/
# (override with BACKUP_DIR)
#
# Contingencies when disk is low:
#   1) refuse to write if free space < MIN_FREE_MB (default 1024)
#   2) prune oldest dumps until under MAX_BACKUP_GB or free space recovers
#   3) keep at least KEEP_MIN newest successful dumps (default 3)
#   4) if still no room, keep a single compressed "emergency" dump and exit 1
set -euo pipefail

export PATH="${HOME}/.local/micromamba/envs/killallmumus-pg/bin:${HOME}/.local/bin:${PATH}"

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Parent of the Grok worktree root OR override
DEFAULT_PARENT="$(cd "${APP_ROOT}/../.." 2>/dev/null && pwd || true)"
# Prefer explicit parent of www worktree when present
if [[ -d /home/vibekilla/.grok/worktrees/www-killallmumuscom ]]; then
  DEFAULT_PARENT="/home/vibekilla/.grok/worktrees/www-killallmumuscom"
fi

BACKUP_DIR="${BACKUP_DIR:-${DEFAULT_PARENT}/db-backups}"
MIN_FREE_MB="${MIN_FREE_MB:-1024}"          # require ≥1 GiB free to start
MAX_BACKUP_GB="${MAX_BACKUP_GB:-5}"        # cap total backup retention
KEEP_MIN="${KEEP_MIN:-3}"                  # always keep N newest if possible
KEEP_DAYS="${KEEP_DAYS:-30}"               # age-based prune (trim dumps older than 30 days)
DB_NAME="${PGDATABASE:-killallmumus}"
PGHOST_TCP="${PGHOST_TCP:-127.0.0.1}"
PGPORT="${PGPORT:-5433}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${BACKUP_DIR}/backup.log"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR" 2>/dev/null || true

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"; }

free_mb() {
  df -Pm "$BACKUP_DIR" | awk 'NR==2{print $4}'
}

backup_total_bytes() {
  find "$BACKUP_DIR" -maxdepth 1 -type f \( -name 'killallmumus-*.sql.gz' -o -name 'killallmumus-*.dump' \) -printf '%s\n' 2>/dev/null \
    | awk '{s+=$1} END{print s+0}'
}

prune_oldest() {
  local need_mb="${1:-0}"
  local files
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/killallmumus-*.sql.gz "$BACKUP_DIR"/killallmumus-*.dump 2>/dev/null || true)
  local count="${#files[@]}"
  local i=0
  for f in "${files[@]}"; do
    i=$((i + 1))
    # never drop below KEEP_MIN newest
    if (( count - (i - 0) < KEEP_MIN )); then
      break
    fi
    # skip the KEEP_MIN newest (indices 0..KEEP_MIN-1)
    if (( i <= KEEP_MIN )); then
      continue
    fi
    log "Pruning old backup: $f"
    rm -f -- "$f"
    if (( need_mb > 0 )) && (( $(free_mb) >= need_mb )); then
      return 0
    fi
    local max_bytes=$((MAX_BACKUP_GB * 1024 * 1024 * 1024))
    if (( $(backup_total_bytes) <= max_bytes )); then
      # still continue age prune below
      :
    fi
  done
}

# Age-based prune (respect KEEP_MIN)
age_prune() {
  local files
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/killallmumus-*.sql.gz 2>/dev/null || true)
  local i=0
  for f in "${files[@]}"; do
    i=$((i + 1))
    if (( i <= KEEP_MIN )); then
      continue
    fi
    if [[ -n "$(find "$f" -mtime +"${KEEP_DAYS}" 2>/dev/null)" ]]; then
      log "Age-pruning (>${KEEP_DAYS}d): $f"
      rm -f -- "$f"
    fi
  done
}

# Cap total size
size_cap_prune() {
  local max_bytes=$((MAX_BACKUP_GB * 1024 * 1024 * 1024))
  while (( $(backup_total_bytes) > max_bytes )); do
    local victim
    victim="$(ls -1t "$BACKUP_DIR"/killallmumus-*.sql.gz 2>/dev/null | tail -n 1 || true)"
    [[ -z "$victim" ]] && break
    # don't delete if only KEEP_MIN remain
    local n
    n="$(ls -1 "$BACKUP_DIR"/killallmumus-*.sql.gz 2>/dev/null | wc -l)"
    if (( n <= KEEP_MIN )); then
      log "WARN: backup set exceeds ${MAX_BACKUP_GB}GiB but only ${n} dumps remain (KEEP_MIN=${KEEP_MIN})"
      break
    fi
    log "Size-cap pruning: $victim"
    rm -f -- "$victim"
  done
}

# Load credentials
if [[ -f "${APP_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${APP_ROOT}/.env"
  set +a
fi

log "=== backup start (free=$(free_mb)MiB dir=$BACKUP_DIR) ==="

# Ensure Postgres is up
if ! pg_isready -h "$PGHOST_TCP" -p "$PGPORT" >/dev/null 2>&1; then
  if [[ -x "${APP_ROOT}/scripts/pg-start.sh" ]]; then
    "${APP_ROOT}/scripts/pg-start.sh" || true
  fi
fi
if ! pg_isready -h "$PGHOST_TCP" -p "$PGPORT" >/dev/null 2>&1; then
  log "ERROR: PostgreSQL not reachable on ${PGHOST_TCP}:${PGPORT}"
  exit 1
fi

# Free space gate
FREE="$(free_mb)"
if (( FREE < MIN_FREE_MB )); then
  log "Low disk (${FREE}MiB < ${MIN_FREE_MB}MiB) — pruning before backup"
  prune_oldest "$MIN_FREE_MB"
  FREE="$(free_mb)"
  if (( FREE < MIN_FREE_MB )); then
    log "ERROR: insufficient storage runway (${FREE}MiB free). Backup aborted."
    # emergency: try a tiny schema-only dump if possible
    EMERGENCY="${BACKUP_DIR}/killallmumus-EMERGENCY-schema-${STAMP}.sql.gz"
    if PGPASSWORD="${PGPASSWORD:-}" pg_dump -h "$PGHOST_TCP" -p "$PGPORT" -U "${PGUSER:-killallmumus}" \
        -d "$DB_NAME" --schema-only 2>/dev/null | gzip -9 >"$EMERGENCY"; then
      log "Wrote emergency schema-only dump: $EMERGENCY"
    fi
    exit 1
  fi
fi

age_prune
size_cap_prune

OUT="${BACKUP_DIR}/killallmumus-${STAMP}.sql.gz"
TMP="${OUT}.partial"

# Full custom-compatible plain SQL, compressed
if ! PGPASSWORD="${PGPASSWORD:-}" pg_dump \
  -h "$PGHOST_TCP" -p "$PGPORT" -U "${PGUSER:-killallmumus}" \
  -d "$DB_NAME" \
  --no-owner --no-acl \
  --format=plain \
  | gzip -9 >"$TMP"; then
  rm -f "$TMP"
  log "ERROR: pg_dump failed"
  exit 1
fi

# Verify gzip integrity
if ! gzip -t "$TMP"; then
  rm -f "$TMP"
  log "ERROR: backup archive corrupt"
  exit 1
fi

mv -f "$TMP" "$OUT"
BYTES="$(stat -c%s "$OUT" 2>/dev/null || echo 0)"
log "OK wrote $OUT (${BYTES} bytes) free_now=$(free_mb)MiB total_backups=$(backup_total_bytes)B"

# Post-write size cap
size_cap_prune

# Write a "latest" pointer (symlink)
ln -sfn "$(basename "$OUT")" "${BACKUP_DIR}/killallmumus-latest.sql.gz"
log "=== backup done ==="
