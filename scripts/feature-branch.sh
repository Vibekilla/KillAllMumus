#!/usr/bin/env bash
# Deprecated optional helper. Preferred: work directly on dev.
#
#   cd /var/www/dev && git checkout dev && git pull
#   # edit + commit + git push origin dev
#   ./scripts/promote-to-live.sh   # when ready for main
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [[ -d .githooks ]]; then
  git config core.hooksPath .githooks
fi

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  cat >&2 <<'EOF'
feature-branch.sh is optional/deprecated.

Preferred workflow:
  cd /var/www/dev
  git checkout dev && git pull origin dev
  # edit…
  git commit -am "feat: …"
  git push origin dev
  ./scripts/promote-to-live.sh    # when ready for live

Optional: still cut a personal branch:
  ./scripts/feature-branch.sh short-name
EOF
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty — commit/stash first." >&2
  git status -sb
  exit 1
fi

SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-')
BRANCH="feature/${SLUG}"

echo "==> Optional branch ${BRANCH} from origin/dev"
git fetch origin dev
git checkout -B "$BRANCH" origin/dev
git push -u origin "$BRANCH" || true
echo "✓ On ${BRANCH} (optional). Merge into dev yourself when ready:"
echo "  git checkout dev && git merge ${BRANCH} && git push origin dev"
