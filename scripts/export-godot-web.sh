#!/usr/bin/env bash
# Export Godot Web build → THIS worktree public_godot/, then mirror to live worktree
# so both /godot/ previews stay in sync without waiting for a full promote.
#
# Usage:
#   ./scripts/export-godot-web.sh              # release → dev + mirror live public_godot
#   ./scripts/export-godot-web.sh --debug
#   ./scripts/export-godot-web.sh --no-mirror  # dev only
#   npm run export:godot
#
# Policy:
#   - Always write export into the git worktree you run from (normally /var/www/dev).
#   - Also rsync → /var/www/killallmumus.com/public_godot for live /godot/ preview
#     (does NOT flip USE_GODOT; live default client stays html-legacy until Phase 7).
#   - Refuse to *run the Godot export* with cwd inside the live worktree.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "${ROOT}" ]]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$ROOT"

MODE="release"
MIRROR=1
for arg in "$@"; do
  case "$arg" in
    --debug|-d) MODE="debug" ;;
    --no-mirror) MIRROR=0 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

GODOT="${GODOT:-$HOME/.local/godot/godot}"
if [[ ! -x "$GODOT" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT=$(command -v godot)
  else
    echo "ERROR: Godot binary not found (set GODOT=... or install to ~/.local/godot/godot)" >&2
    exit 1
  fi
fi

OUT_DIR="$ROOT/public_godot"
OUT_HTML="$OUT_DIR/index.html"
mkdir -p "$OUT_DIR"

case "$ROOT" in
  */killallmumus.com)
    echo "ERROR: refusing to export inside live worktree ($ROOT)." >&2
    echo "  Run from /var/www/dev so sources are on the dev branch, then mirror." >&2
    exit 1
    ;;
esac

echo "==> Godot Web export ($MODE)"
echo "    project: $ROOT/godot"
echo "    output:  $OUT_HTML"
echo "    binary:  $GODOT"

EXPORT_FLAG="--export-release"
if [[ "$MODE" == "debug" ]]; then
  EXPORT_FLAG="--export-debug"
fi

"$GODOT" --headless --path "$ROOT/godot" $EXPORT_FLAG "Web" "$OUT_HTML"

if [[ ! -f "$OUT_DIR/index.pck" ]] || [[ ! -f "$OUT_DIR/index.wasm" ]]; then
  echo "ERROR: export incomplete — missing index.pck or index.wasm in $OUT_DIR" >&2
  ls -la "$OUT_DIR" | head -20
  exit 1
fi

if [[ -x "$ROOT/scripts/patch-godot-music.sh" ]]; then
  bash "$ROOT/scripts/patch-godot-music.sh" "$OUT_HTML"
fi

# Ensure non-threaded note is visible in logs (music needs no COEP)
if grep -q 'GODOT_THREADS_ENABLED = true' "$OUT_HTML" 2>/dev/null; then
  echo "  WARN: threads ENABLED — server will set COEP; YouTube lofi may fail" >&2
else
  echo "  threads disabled — server will omit COEP (YouTube lofi allowed)"
fi

PCK_SZ=$(stat -c%s "$OUT_DIR/index.pck" 2>/dev/null || stat -f%z "$OUT_DIR/index.pck")
WASM_SZ=$(stat -c%s "$OUT_DIR/index.wasm" 2>/dev/null || stat -f%z "$OUT_DIR/index.wasm")
echo "✓ export OK → $OUT_DIR"
echo "  index.pck  $(numfmt --to=iec "$PCK_SZ" 2>/dev/null || echo "$PCK_SZ") bytes"
echo "  index.wasm $(numfmt --to=iec "$WASM_SZ" 2>/dev/null || echo "$WASM_SZ") bytes"

# Mirror to live worktree public_godot for https://killallmumus.com/godot/ preview
LIVE_GODOT="/var/www/killallmumus.com/public_godot"
if [[ "$MIRROR" -eq 1 ]] && [[ -d "/var/www/killallmumus.com" ]]; then
  mkdir -p "$LIVE_GODOT"
  echo "==> Mirror → $LIVE_GODOT (live /godot/ preview; client default unchanged)"
  rsync -a --delete \
    --exclude 'share-win.png' \
    "$OUT_DIR/" "$LIVE_GODOT/"
  # Re-patch live html in case rsync overwrote with already-patched file (idempotent)
  if [[ -x "$ROOT/scripts/patch-godot-music.sh" ]]; then
    bash "$ROOT/scripts/patch-godot-music.sh" "$LIVE_GODOT/index.html" 2>/dev/null || true
  fi
  echo "✓ mirrored live public_godot"
  echo "  dev:  https://dev.killallmumus.com/godot/   (or / when USE_GODOT=1)"
  echo "  live: https://killallmumus.com/godot/       (html-legacy still default /)"
else
  if [[ "$MIRROR" -eq 0 ]]; then
    echo "  (mirror skipped --no-mirror)"
  else
    echo "  (no live worktree at /var/www/killallmumus.com — skip mirror)"
  fi
fi
