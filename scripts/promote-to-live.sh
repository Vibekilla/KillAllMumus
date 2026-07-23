#!/usr/bin/env bash
# Promote dev → main (live) by merge + push. No GitHub PR required.
#
#   ./scripts/promote-to-live.sh
#   ./scripts/promote-to-live.sh --ff-only   # refuse non-fast-forward
#   ./scripts/promote-to-live.sh --no-push   # merge locally only
set -euo pipefail

FF_ONLY=0
DO_PUSH=1
for arg in "$@"; do
  case "$arg" in
    --ff-only) FF_ONLY=1 ;;
    --no-push) DO_PUSH=0 ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty — commit or stash first." >&2
  git status -sb
  exit 1
fi

git fetch origin dev main --prune

AHEAD=$(git rev-list --count "origin/main..origin/dev" 2>/dev/null || echo 0)
if [[ "${AHEAD}" -eq 0 ]]; then
  echo "origin/dev has nothing new vs origin/main — nothing to promote."
  git checkout -B main origin/main
  exit 0
fi

echo "==> Promote origin/dev → main (${AHEAD} commit(s) ahead)"
git log --oneline --no-merges "origin/main..origin/dev" | head -30 || true

git checkout -B main origin/main

if [[ "$FF_ONLY" -eq 1 ]]; then
  git merge --ff-only origin/dev
else
  # Prefer fast-forward; otherwise create a merge commit
  if git merge-base --is-ancestor origin/main origin/dev 2>/dev/null; then
    git merge --ff-only origin/dev
  else
    git merge --no-ff origin/dev -m "promote: merge dev into main (live)"
  fi
fi

if [[ "$DO_PUSH" -eq 1 ]]; then
  echo "==> Push origin main"
  git push origin main
fi

echo "✓ Live main @ $(git rev-parse --short HEAD)"
echo "  CI deploy runs on main. dev is left as-is (not force-reset)."
