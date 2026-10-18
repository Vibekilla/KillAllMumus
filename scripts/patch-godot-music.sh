#!/usr/bin/env bash
# Inject YouTube lofi bridge into Godot web export HTML (after godot --export).
# Re-patches when the shuffled playlist marker or SoftPause API is missing.
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
html_path = Path("$HTML")
snip_path = Path("$SNIP")
html = html_path.read_text()
snip = snip_path.read_text()

# Current bridge: shuffled playlist marker plus the soft-pause API.
MARKER = "PLC6gDrhD6E1X_mZ8arMGO48Ta-cpsnuzR"
if (
    MARKER in html
    and "ytKickUntil" in html
    and "kamMusicSoftPause" in html
    and "kamMusicPlay" in html
    and "playVideoAt" not in html
):
    print("music bridge up to date in", html_path)
    raise SystemExit(0)

# Strip from the lofi comment (or ytmusic div) through the kamMusic IIFE.
# The iframe_api tag closes before kamMusicPlay, so a first-</script> match
# would leave the player script in place.
cleaned = html
start = cleaned.find("<!-- HTML lofi stream")
if start < 0:
    start = cleaned.find('<div id="ytmusic"')
if start < 0:
    raise SystemExit("no music bridge to replace in %s" % html_path)
anchor = cleaned.find("kamMusicPlay", start)
if anchor < 0:
    raise SystemExit("music bridge has no kamMusicPlay in %s" % html_path)
end = cleaned.find("</script>", anchor)
if end < 0:
    raise SystemExit("music bridge script is not closed in %s" % html_path)
end += len("</script>")
while end < len(cleaned) and cleaned[end] in " \t\r\n":
    end += 1
cleaned = cleaned[:start] + cleaned[end:]

if "</head>" not in cleaned:
    raise SystemExit("no </head> in export html")

if "kamMusicPlay" in cleaned:
    raise SystemExit("could not strip old music bridge from %s" % html_path)

html_out = cleaned.replace("</head>", snip + "\n</head>", 1)
html_path.write_text(html_out)
print("patched", html_path)
PY
