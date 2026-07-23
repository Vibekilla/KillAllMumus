#!/usr/bin/env bash
# Cut a new feature/* branch from latest origin/dev.
# All work commits happen HERE — never on dev or main.
#
#   ./scripts/feature-branch.sh short-name
#   # edit + commit on feature/*
#   ./scripts/ship-feature.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Repo-local hooks refuse commits on main/dev (committed under .githooks/)
if [[ -d .githooks ]]; then
  git config core.hooksPath .githooks
fi

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  cat >&2 <<'EOF'
Usage: ./scripts/feature-branch.sh <feature-name>

Creates feature/<name> from origin/dev. Commit only on that branch, then:
  ./scripts/ship-feature.sh            # PR → merge into dev → delete branch
  ./scripts/ship-feature.sh --promote  # same + promote dev → main (live)
EOF
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty — commit/stash on the current feature branch first." >&2
  git status -sb
  exit 1
fi

SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-')
BRANCH="feature/${SLUG}"

if [[ "$BRANCH" == "feature/dev" || "$BRANCH" == "feature/main" ]]; then
  echo "Invalid feature name: $NAME" >&2
  exit 1
fi

echo "==> Fetch origin/dev"
git fetch origin dev

if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  echo "Remote ${BRANCH} already exists — checking it out (not recreating)." >&2
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/${BRANCH}"
  git pull --ff-only origin "$BRANCH" || true
  git branch -u "origin/${BRANCH}" 2>/dev/null || true
  echo "✓ On existing ${BRANCH}"
  exit 0
fi

# Always start from latest integration tip (no force, no commit on dev)
git checkout -B "$BRANCH" origin/dev
git push -u origin "$BRANCH"

echo "✓ ${BRANCH} cut from origin/dev"
echo "  Make commits only on this branch."
echo "  When done:  ./scripts/ship-feature.sh"
