#!/usr/bin/env bash
# Promote integration → production via PR only.
# Never commits on main or dev — only merges an existing PR.
#
#   ./scripts/promote-to-live.sh           # open + merge PR  dev → main
#   ./scripts/promote-to-live.sh --draft   # open PR only
set -euo pipefail

DRAFT=0
MERGE=1
for arg in "$@"; do
  case "$arg" in
    --draft) DRAFT=1; MERGE=0 ;;
    --help|-h)
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

if ! command -v gh >/dev/null 2>&1; then
  echo "gh required" >&2
  exit 1
fi

# Refuse if dirty work would be ambiguous
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty — stash/commit on a feature/* branch first." >&2
  exit 1
fi

git fetch origin dev main --prune

AHEAD=$(git rev-list --count "origin/main..origin/dev" 2>/dev/null || echo 0)
if [[ "${AHEAD}" -eq 0 ]]; then
  echo "origin/dev has nothing new vs origin/main — nothing to promote."
  exit 0
fi

NOTES=$(git log --pretty=format:'- %s' --no-merges "origin/main..origin/dev" | head -40 || true)
TITLE="promote: dev → main (live)"
BODY=$(cat <<EOF
## Promote to production

### Notes since main
${NOTES}

Merging deploys **live** (\`main\`).
CI refreshes \`dev\` to match \`main\` after deploy (rollback mirror).

No direct commits on \`main\` — this PR only.
EOF
)

PEXIST=$(gh pr list --base main --head dev --state open --json number --jq '.[0].number // empty')
if [[ -z "$PEXIST" ]]; then
  ARGS=(pr create --base main --head dev --title "$TITLE" --body "$BODY")
  [[ "$DRAFT" -eq 1 ]] && ARGS+=(--draft)
  gh "${ARGS[@]}"
  PEXIST=$(gh pr list --base main --head dev --state open --json number --jq '.[0].number')
else
  gh pr edit "$PEXIST" --title "$TITLE" --body "$BODY" >/dev/null || true
fi

echo "Promote PR #${PEXIST}"
gh pr view "$PEXIST" --json url --jq .url

if [[ "$MERGE" -eq 0 ]]; then
  echo "Draft/open only — not merged."
  exit 0
fi

gh pr merge "$PEXIST" --merge 2>/dev/null || gh pr merge "$PEXIST" --squash

git fetch origin main
# Local tip only — never invent commits on main
git checkout -B main origin/main

echo "✓ Live main @ $(git rev-parse --short HEAD)"
echo "  After CI deploy, dev is force-refreshed to main by Actions."
