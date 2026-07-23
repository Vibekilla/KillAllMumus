#!/usr/bin/env bash
# Cohesive feature lifecycle — one entrypoint, no leftover branches.
#
#   feature/*  (from dev)  →  PR into dev  →  merge  →  delete feature branch
#   optional:  --promote   also open/merge promote PR  dev → main (live)
#
# Usage (from a feature/* branch with commits pushed or unpushed):
#   ./scripts/ship-feature.sh              # PR + merge into dev + delete branch
#   ./scripts/ship-feature.sh --promote    # same, then promote dev → main
#   ./scripts/ship-feature.sh --draft      # open PR only (no merge)
#   ./scripts/ship-feature.sh --no-push    # assume already pushed
#
# Cut a new branch first with:  ./scripts/feature-branch.sh <name>
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
      sed -n '2,18p' "$0" | sed 's/^# \?//'
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
  echo "Must be on feature/* (currently: $BRANCH)" >&2
  echo "Start with: ./scripts/feature-branch.sh <name>" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean — commit or stash first." >&2
  git status -sb
  exit 1
fi

BASE=dev

echo "==> Fetch origin"
git fetch origin dev main --prune

if [[ "$DO_PUSH" -eq 1 ]]; then
  echo "==> Push $BRANCH"
  git push -u origin HEAD
fi

TITLE=$(git log -1 --pretty=format:'%s')
NOTES=$(git log --pretty=format:'- %s' --no-merges "origin/${BASE}..HEAD" | head -40 || true)
BODY=$(cat <<EOF
## Feature branch

Source: \`${BRANCH}\`  
Target: \`${BASE}\` (integration)

### Feature notes
${NOTES:-"- (see commits)"}

### Policy
- \`public/index.html\` remains the live game source of truth until Godot cutover.
- After this merges to \`${BASE}\`, promote \`${BASE}\` → \`main\` when ready for production.
- Feature branch is deleted on merge (no leftovers).
EOF
)

echo "==> Ensure PR ${BRANCH} → ${BASE}"
EXISTING=$(gh pr list --head "$BRANCH" --base "$BASE" --state open --json number --jq '.[0].number // empty')
if [[ -z "$EXISTING" ]]; then
  # Already merged?
  MERGED=$(gh pr list --head "$BRANCH" --base "$BASE" --state merged --json number --jq '.[0].number // empty')
  if [[ -n "$MERGED" ]]; then
    echo "Already merged as PR #$MERGED"
    PR="$MERGED"
  else
    CREATE_ARGS=(pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY")
    if [[ "$DRAFT" -eq 1 ]]; then
      CREATE_ARGS+=(--draft)
    fi
    PR_URL=$(gh "${CREATE_ARGS[@]}")
    echo "Created $PR_URL"
    PR=$(gh pr list --head "$BRANCH" --base "$BASE" --json number --jq '.[0].number')
  fi
else
  PR="$EXISTING"
  gh pr edit "$PR" --title "$TITLE" --body "$BODY" >/dev/null
  echo "Updated PR #$PR"
fi

if [[ "$MERGE" -eq 0 ]]; then
  gh pr view "$PR" --web 2>/dev/null || gh pr view "$PR"
  echo "Draft/open only — not merging."
  exit 0
fi

echo "==> Merge PR #$PR (delete feature branch)"
# Prefer squash for one clean commit on dev; fallback to merge commit
if ! gh pr merge "$PR" --squash --delete-branch --subject "$TITLE" 2>/dev/null; then
  gh pr merge "$PR" --merge --delete-branch
fi

echo "==> Sync local to origin/$BASE"
git checkout "$BASE"
git pull --ff-only origin "$BASE"
# Drop local feature branch if still present
git branch -D "$BRANCH" 2>/dev/null || true

if [[ "$PROMOTE" -eq 1 ]]; then
  echo "==> Promote $BASE → main (live)"
  git fetch origin main
  PROMOTE_TITLE="promote: ${BASE} → main (live)"
  PROMOTE_NOTES=$(git log --pretty=format:'- %s' --no-merges "origin/main..origin/${BASE}" | head -40 || true)
  PROMOTE_BODY=$(cat <<EOF
## Promote to production

### Notes since main
${PROMOTE_NOTES:-"- (none)"}

Merging deploys **live** (\`main\`). CI refreshes \`${BASE}\` as rollback mirror after deploy.
EOF
)
  PEXIST=$(gh pr list --base main --head "$BASE" --state open --json number --jq '.[0].number // empty')
  if [[ -z "$PEXIST" ]]; then
    gh pr create --base main --head "$BASE" --title "$PROMOTE_TITLE" --body "$PROMOTE_BODY"
    PEXIST=$(gh pr list --base main --head "$BASE" --state open --json number --jq '.[0].number')
  fi
  echo "Merging promote PR #$PEXIST"
  gh pr merge "$PEXIST" --merge || gh pr merge "$PEXIST" --squash
  git checkout main
  git pull --ff-only origin main
fi

echo "✓ Shipped ${BRANCH} → ${BASE}$( [[ $PROMOTE -eq 1 ]] && echo ' → main' || true )"
gh pr view "$PR" --json url,state,mergedAt --jq '"  PR: \(.url)  state=\(.state)  merged=\(.mergedAt)"' 2>/dev/null || true
