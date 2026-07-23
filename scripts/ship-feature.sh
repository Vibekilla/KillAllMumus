#!/usr/bin/env bash
# Ship the current feature/* branch. Never commits to dev/main.
#
#   feature/*  →  push  →  PR into dev  →  merge  →  delete feature branch
#   optional: --promote  →  PR dev → main (live) + merge
#
# Usage (must be on feature/* with a clean tree):
#   ./scripts/ship-feature.sh
#   ./scripts/ship-feature.sh --promote
#   ./scripts/ship-feature.sh --draft     # PR only, no merge
set -euo pipefail

DRAFT=0
PROMOTE=0
DO_PUSH=1
MERGE=1

for arg in "$@"; do
  case "$arg" in
    --draft) DRAFT=1; MERGE=0 ;;
    --promote) PROMOTE=1 ;;
    --no-push) DO_PUSH=0 ;;
    --help|-h)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) required" >&2
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != feature/* ]]; then
  echo "Refuse to ship from '${BRANCH}' — only feature/* may ship." >&2
  echo "  ./scripts/feature-branch.sh <name>   # cut from dev" >&2
  echo "  # commit on feature/* only" >&2
  echo "  ./scripts/ship-feature.sh" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean — commit on ${BRANCH} first (never on dev/main)." >&2
  git status -sb
  exit 1
fi

# Must have commits ahead of origin/dev
git fetch origin dev main --prune
AHEAD=$(git rev-list --count "origin/dev..HEAD" 2>/dev/null || echo 0)
if [[ "${AHEAD}" -eq 0 ]]; then
  echo "No commits on ${BRANCH} ahead of origin/dev — nothing to ship." >&2
  exit 1
fi

BASE=dev
TITLE=$(git log -1 --pretty=format:'%s')
NOTES=$(git log --pretty=format:'- %s' --no-merges "origin/${BASE}..HEAD" | head -40 || true)
BODY=$(cat <<EOF
## Feature

\`${BRANCH}\` → \`${BASE}\`

### Notes
${NOTES}

### Lifecycle
Shipped via \`./scripts/ship-feature.sh\` (PR → merge → delete feature branch).
Commits are never made directly on \`dev\` or \`main\`.
EOF
)

if [[ "$DO_PUSH" -eq 1 ]]; then
  echo "==> Push ${BRANCH}"
  git push -u origin HEAD
fi

echo "==> PR ${BRANCH} → ${BASE}"
EXISTING=$(gh pr list --head "$BRANCH" --base "$BASE" --state open --json number --jq '.[0].number // empty')
if [[ -z "$EXISTING" ]]; then
  MERGED=$(gh pr list --head "$BRANCH" --base "$BASE" --state merged --json number --jq '.[0].number // empty')
  if [[ -n "$MERGED" ]]; then
    echo "Already merged as PR #${MERGED}"
    PR="$MERGED"
  else
    ARGS=(pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY")
    [[ "$DRAFT" -eq 1 ]] && ARGS+=(--draft)
    gh "${ARGS[@]}"
    PR=$(gh pr list --head "$BRANCH" --base "$BASE" --json number --jq '.[0].number')
  fi
else
  PR="$EXISTING"
  gh pr edit "$PR" --title "$TITLE" --body "$BODY" >/dev/null
  echo "Updated PR #${PR}"
fi

if [[ "$MERGE" -eq 0 ]]; then
  gh pr view "$PR" --json url --jq .url
  echo "Draft/open only — not merged."
  exit 0
fi

echo "==> Merge PR #${PR} + delete ${BRANCH}"
# Squash keeps dev history linear (one commit per feature). Feature branch deleted.
if ! gh pr merge "$PR" --squash --delete-branch --subject "$TITLE" 2>/dev/null; then
  gh pr merge "$PR" --merge --delete-branch
fi

echo "==> Local: track origin/${BASE} (read-only tip — do not commit here)"
git fetch origin "$BASE"
git checkout -B "$BASE" "origin/${BASE}"
git branch -D "$BRANCH" 2>/dev/null || true

if [[ "$PROMOTE" -eq 1 ]]; then
  echo "==> Promote ${BASE} → main (PR only; no direct commits)"
  ./scripts/promote-to-live.sh
fi

echo "✓ Shipped ${BRANCH} → ${BASE}"
echo "  Next work:  ./scripts/feature-branch.sh <next-name>"
gh pr view "$PR" --json url,state,mergedAt --jq '"  \(.url)  \(.state)  \(.mergedAt)"' 2>/dev/null || true
