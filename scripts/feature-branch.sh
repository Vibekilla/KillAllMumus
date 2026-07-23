#!/usr/bin/env bash
# Cut a feature branch from latest origin/dev.
# Ship it with:  ./scripts/ship-feature.sh   (PR → merge → delete)
set -euo pipefail
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <feature-name>" >&2
  echo "Then:  ./scripts/ship-feature.sh          # PR + merge into dev + delete branch" >&2
  echo "       ./scripts/ship-feature.sh --promote  # also promote dev → main (live)" >&2
  exit 1
fi
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-')
BRANCH="feature/${SLUG}"
git fetch origin dev
git checkout -B "$BRANCH" origin/dev
git push -u origin "$BRANCH"
echo "✓ ${BRANCH} from origin/dev"
echo "  Commit work, then:  ./scripts/ship-feature.sh"
