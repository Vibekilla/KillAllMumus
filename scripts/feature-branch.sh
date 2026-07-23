#!/usr/bin/env bash
# Cut a feature branch from latest origin/dev with a conventional commit-ready name.
# Usage: ./scripts/feature-branch.sh short-feature-name
set -euo pipefail
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <feature-name>" >&2
  exit 1
fi
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-')
BRANCH="feature/${SLUG}"
git fetch origin dev
git checkout -B "$BRANCH" origin/dev
git push -u origin "$BRANCH"
echo "✓ Branch $BRANCH created from dev"
echo "  Work here, commit with notes: feat: … / fix: … / chore: …"
echo "  Push opens/updates a PR into dev (CI)."
echo "  Merge to dev → promote PR to main for live → dev refreshed as rollback mirror."
