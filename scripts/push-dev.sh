#!/usr/bin/env bash
# Commit (optional) and push the current branch to origin.
# Intended for day-to-day work on `dev`.
#
#   ./scripts/push-dev.sh                 # push only (must be clean or already committed)
#   ./scripts/push-dev.sh -m "feat: …"    # git add -A && commit && push
#   ./scripts/push-dev.sh --no-add -m "…" # commit staged only
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MSG=""
NO_ADD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message) MSG="${2:-}"; shift 2 ;;
    --no-add) NO_ADD=1; shift ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $1 (try --help)" >&2
      exit 1
      ;;
  esac
done

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == "HEAD" ]]; then
  echo "Detached HEAD — checkout dev or main first." >&2
  exit 1
fi

if [[ -n "$MSG" ]]; then
  if [[ "$NO_ADD" -eq 0 ]]; then
    git add -A
  fi
  if [[ -z "$(git status --porcelain)" ]] && [[ -z "$(git diff --cached --name-only)" ]]; then
    echo "Nothing to commit — pushing ${BRANCH}."
  else
    git commit -m "$MSG"
  fi
elif [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty. Pass -m \"message\" to commit, or commit manually." >&2
  git status -sb
  exit 1
fi

echo "==> Push origin ${BRANCH}"
git push -u origin HEAD
echo "✓ ${BRANCH} @ $(git rev-parse --short HEAD)"
if [[ "$BRANCH" != "dev" && "$BRANCH" != "main" ]]; then
  echo "  (Tip: day-to-day work belongs on dev: git checkout dev)"
fi
