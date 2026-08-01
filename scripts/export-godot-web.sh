#!/usr/bin/env bash
# Export Godot Web build into THIS worktree's public_godot/ (always dev when run from /var/www/dev).
#
# Usage:
#   ./scripts/export-godot-web.sh           # release export → <repo>/public_godot/
#   ./scripts/export-godot-web.sh --debug  # debug export
#   npm run export:godot
#
# Policy: export ALWAYS lands on the repo that owns the godot/ project (dev worktree).
# Live (/var/www/killallmumus.com) gets public_godot only via git promote (dev → main).
# Do NOT write exports directly into the live worktree.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "${ROOT}" ]]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$ROOT"

MODE="release"
for arg in "$@"; do
  case "$arg" in
    --debug|-d) MODE="debug" ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
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

# Refuse accidental export into live worktree from a wrong cwd.
case "$ROOT" in
  */killallmumus.com)
    echo "ERROR: refusing to export inside live worktree ($ROOT)." >&2
    echo "  Run from /var/www/dev so public_godot lands on dev, then promote." >&2
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

# Explicit path overrides export_presets.cfg so we never write to live by mistake.
"$GODOT" --headless --path "$ROOT/godot" $EXPORT_FLAG "Web" "$OUT_HTML"

if [[ ! -f "$OUT_DIR/index.pck" ]] || [[ ! -f "$OUT_DIR/index.wasm" ]]; then
  echo "ERROR: export incomplete — missing index.pck or index.wasm in $OUT_DIR" >&2
  ls -la "$OUT_DIR" | head -20
  exit 1
fi

if [[ -x "$ROOT/scripts/patch-godot-music.sh" ]]; then
  bash "$ROOT/scripts/patch-godot-music.sh" "$OUT_HTML"
fi

PCK_SZ=$(stat -c%s "$OUT_DIR/index.pck" 2>/dev/null || stat -f%z "$OUT_DIR/index.pck")
WASM_SZ=$(stat -c%s "$OUT_DIR/index.wasm" 2>/dev/null || stat -f%z "$OUT_DIR/index.wasm")
echo "✓ export OK → $OUT_DIR"
echo "  index.pck  $(numfmt --to=iec "$PCK_SZ" 2>/dev/null || echo "$PCK_SZ") bytes"
echo "  index.wasm $(numfmt --to=iec "$WASM_SZ" 2>/dev/null || echo "$WASM_SZ") bytes"
echo "  (live gets this only after: git push origin dev && ./scripts/promote-to-live.sh)"
