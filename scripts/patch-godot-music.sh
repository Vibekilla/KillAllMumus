#!/usr/bin/env bash
# Inject YouTube lofi bridge into Godot web export HTML (after godot --export).
# Re-patches when SoftPause API is missing so residual music fixes land on re-export.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="${1:-$ROOT/public_godot/index.html}"
SNIP="$ROOT/godot/export/web_music_head.html"
if [[ ! -f "$HTML" ]]; then
  echo "missing $HTML" >&2
  exit 1
fi
if [[ ! -f "$SNIP" ]]; then
  echo "missing $SNIP" >&2
  exit 1
fi

python3 - <<PY
from pathlib import Path
import re
html_path = Path("$HTML")
snip_path = Path("$SNIP")
html = html_path.read_text()
snip = snip_path.read_text()

# Already has current soft-pause API → done
if "kamMusicSoftPause" in html and "kamMusicPlay" in html:
    print("music bridge up to date in", html_path)
    raise SystemExit(0)

# Strip any older music bridge block (ytmusic div + iframe_api + kamMusic IIFE)
# Matches our head snippet between optional comment and script end.
patterns = [
    r'<!-- HTML lofi stream[\s\S]*?</script>\s*',
    r'<div id="ytmusic"[\s\S]*?</script>\s*',
]
cleaned = html
for pat in patterns:
    cleaned2 = re.sub(pat, "", cleaned, count=1)
    if cleaned2 != cleaned:
        cleaned = cleaned2
        break

if "</head>" not in cleaned:
    raise SystemExit("no </head> in export html")

if "kamMusicPlay" in cleaned and "kamMusicSoftPause" not in cleaned:
    # Fallback: inject SoftPause next to kamMusicPause if partial bridge remains
    if "window.kamMusicPause" in cleaned:
        cleaned = cleaned.replace(
            "window.kamMusicPause",
            "window.kamMusicSoftPause=function(){try{if(window.__kamYtPlayer&&window.__kamYtPlayer.pauseVideo)window.__kamYtPlayer.pauseVideo();}catch(e){}};window.kamMusicPause",
            1,
        )
        html_path.write_text(cleaned)
        print("patched SoftPause into existing bridge", html_path)
        raise SystemExit(0)

html_out = cleaned.replace("</head>", snip + "\n</head>", 1)
html_path.write_text(html_out)
print("patched", html_path)
PY
