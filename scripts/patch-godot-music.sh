#!/usr/bin/env bash
# Inject YouTube lofi bridge into Godot web export HTML (after godot --export).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="${1:-$ROOT/public_godot/index.html}"
SNIP="$ROOT/godot/export/web_music_head.html"
if [[ ! -f "$HTML" ]]; then
  echo "missing $HTML" >&2
  exit 1
fi
if grep -q 'kamMusicPlay' "$HTML"; then
  echo "music bridge already present in $HTML"
  exit 0
fi
if [[ ! -f "$SNIP" ]]; then
  echo "missing $SNIP" >&2
  exit 1
fi
# Insert before </head>
python3 - <<PY
from pathlib import Path
html = Path("$HTML").read_text()
snip = Path("$SNIP").read_text()
if "kamMusicPlay" in html:
    print("already patched")
else:
    if "</head>" not in html:
        raise SystemExit("no </head> in export html")
    html = html.replace("</head>", snip + "\n</head>", 1)
    Path("$HTML").write_text(html)
    print("patched", "$HTML")
PY
