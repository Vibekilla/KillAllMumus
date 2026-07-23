#!/usr/bin/env bash
# Safe commit wrapper: only allows commits on feature/* branches.
# Usage: ./scripts/commit-on-feature.sh -m "feat: …"   (same args as git commit)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in
  feature/*) ;;
  *)
    echo "Refuse commit on '${BRANCH}'." >&2
    echo "All work commits must be on feature/*:" >&2
    echo "  ./scripts/feature-branch.sh <name>" >&2
    echo "  ./scripts/commit-on-feature.sh -m 'feat: …'" >&2
    echo "  ./scripts/ship-feature.sh" >&2
    exit 1
    ;;
esac

if [[ "$BRANCH" == "main" || "$BRANCH" == "dev" ]]; then
  echo "Refuse commit on protected branch ${BRANCH}" >&2
  exit 1
fi

exec git commit "$@"
