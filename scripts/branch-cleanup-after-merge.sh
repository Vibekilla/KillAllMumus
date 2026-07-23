#!/usr/bin/env bash
# Delete a feature branch after it is successfully merged (local + remote).
# Usage:
#   scripts/branch-cleanup-after-merge.sh feature/full-html-godot-parity
#   scripts/branch-cleanup-after-merge.sh feature/foo --base main
#
# Policy (Kill All Mumus): after a feature branch is merged to its base via PR
# and CI/sign-off, run this so the branch does not linger.

set -euo pipefail

BRANCH="${1:-}"
BASE="main"
if [[ "${2:-}" == "--base" ]]; then
  BASE="${3:-main}"
fi

if [[ -z "$BRANCH" ]]; then
  echo "Usage: $0 <branch> [--base main|dev]"
  exit 1
fi

if [[ "$BRANCH" == "main" || "$BRANCH" == "dev" || "$BRANCH" == "master" ]]; then
  echo "Refusing to delete protected branch: $BRANCH"
  exit 1
fi

cd "$(git rev-parse --show-toplevel)"

echo "==> Fetching origin…"
git fetch origin --prune

# Prefer GitHub CLI merge detection when available
if command -v gh >/dev/null 2>&1; then
  STATE=$(gh pr list --head "$BRANCH" --state merged --json number,title --jq '.[0].number // empty' 2>/dev/null || true)
  if [[ -z "$STATE" ]]; then
    OPEN=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number // empty' 2>/dev/null || true)
    if [[ -n "$OPEN" ]]; then
      echo "PR #$OPEN for $BRANCH is still OPEN — merge it first, then re-run."
      exit 2
    fi
    echo "No merged PR found for head=$BRANCH via gh. Checking if tip is contained in origin/$BASE…"
  else
    echo "Found merged PR #$STATE for $BRANCH"
  fi
fi

git checkout "$BASE" 2>/dev/null || git checkout "origin/$BASE" -B "$BASE"
git pull --ff-only origin "$BASE" || true

# Ensure branch tip is an ancestor of base (merged)
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  if ! git merge-base --is-ancestor "origin/$BRANCH" "origin/$BASE" 2>/dev/null; then
    echo "origin/$BRANCH is NOT fully merged into origin/$BASE — aborting delete."
    exit 3
  fi
elif git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  if ! git merge-base --is-ancestor "$BRANCH" "origin/$BASE" 2>/dev/null; then
    echo "local $BRANCH is NOT fully merged into origin/$BASE — aborting delete."
    exit 3
  fi
else
  echo "Branch $BRANCH not found locally or on origin (already deleted?)."
  exit 0
fi

echo "==> Deleting local branch $BRANCH (if present)…"
git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH" 2>/dev/null || true

echo "==> Deleting remote origin/$BRANCH…"
git push origin --delete "$BRANCH" 2>/dev/null || echo "(remote already gone)"

echo "==> Done. Remaining branches:"
git branch -vv | head -20
