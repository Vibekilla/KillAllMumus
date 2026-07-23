#!/usr/bin/env bash
# Promote dev → main (live) by merge + push. No GitHub PR required.
# Works with the two-worktree layout:
#   /var/www/dev              → branch dev
#   /var/www/killallmumus.com → branch main
#
#   ./scripts/promote-to-live.sh
#   ./scripts/promote-to-live.sh --ff-only
#   ./scripts/promote-to-live.sh --no-push
set -euo pipefail

FF_ONLY=0
DO_PUSH=1
for arg in "$@"; do
  case "$arg" in
    --ff-only) FF_ONLY=1 ;;
    --no-push) DO_PUSH=0 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

# Always run from the real git common dir / any linked worktree
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

# Prefer the worktree that already has `main` checked out (avoids
# "main is already used by worktree at …" when promoting from /var/www/dev).
MAIN_WT=""
while read -r path _rest; do
  if [[ "$_rest" == *"[main]"* ]] || [[ "$_rest" == *"[main "* ]]; then
    MAIN_WT="$path"
    break
  fi
done < <(git worktree list)

if [[ -z "$MAIN_WT" ]]; then
  # No main worktree: try common live path, else create a temp worktree
  if [[ -d /var/www/killallmumus.com/.git ]] || [[ -f /var/www/killallmumus.com/.git ]]; then
    MAIN_WT=/var/www/killallmumus.com
  fi
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree dirty in $(pwd) — commit or stash first." >&2
  git status -sb
  exit 1
fi

git fetch origin dev main --prune

AHEAD=$(git rev-list --count "origin/main..origin/dev" 2>/dev/null || echo 0)
if [[ "${AHEAD}" -eq 0 ]]; then
  echo "origin/dev has nothing new vs origin/main — nothing to promote."
  if [[ -n "$MAIN_WT" ]]; then
    git -C "$MAIN_WT" pull --ff-only origin main 2>/dev/null || true
  fi
  exit 0
fi

echo "==> Promote origin/dev → main (${AHEAD} commit(s) ahead)"
git log --oneline --no-merges "origin/main..origin/dev" | head -30 || true

run_in_main() {
  local dir="$1"
  git -C "$dir" fetch origin dev main --prune
  # Ensure on main tracking origin/main
  local cur
  cur=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
  if [[ "$cur" != "main" ]]; then
    git -C "$dir" checkout main
  fi
  git -C "$dir" pull --ff-only origin main || git -C "$dir" reset --hard origin/main

  if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
    echo "Main worktree dirty at $dir — clean it before promote." >&2
    git -C "$dir" status -sb
    exit 1
  fi

  if [[ "$FF_ONLY" -eq 1 ]]; then
    git -C "$dir" merge --ff-only origin/dev
  else
    if git merge-base --is-ancestor origin/main origin/dev 2>/dev/null; then
      git -C "$dir" merge --ff-only origin/dev
    else
      git -C "$dir" merge --no-ff origin/dev -m "promote: merge dev into main (live)"
    fi
  fi

  if [[ "$DO_PUSH" -eq 1 ]]; then
    echo "==> Push origin main"
    git -C "$dir" push origin main
  fi
  echo "✓ Live main @ $(git -C "$dir" rev-parse --short HEAD)"
}

if [[ -n "$MAIN_WT" ]]; then
  echo "Using main worktree: $MAIN_WT"
  run_in_main "$MAIN_WT"
else
  # Fall back: push refs if fast-forward, else temp worktree
  if git merge-base --is-ancestor origin/main origin/dev 2>/dev/null; then
    if [[ "$DO_PUSH" -eq 1 ]]; then
      git push origin origin/dev:main
    fi
    echo "✓ Live main @ $(git rev-parse --short origin/dev) (ff push)"
  else
    TMP=$(mktemp -d)
    trap 'git worktree remove --force "$TMP" 2>/dev/null || rm -rf "$TMP"' EXIT
    git worktree add --detach "$TMP" origin/main
    run_in_main "$TMP"
  fi
fi

# Keep origin/dev from looking "N commits behind main" after promote merges.
# Merge main → dev (no force-reset). Safe: only adds promote merge commits.
sync_dev_with_main() {
  git fetch origin dev main --prune
  local BEHIND
  BEHIND=$(git rev-list --count "origin/dev..origin/main" 2>/dev/null || echo 0)
  if [[ "${BEHIND}" -eq 0 ]]; then
    echo "  dev already contains main — no sync needed."
    return 0
  fi
  echo "==> Sync origin/dev with origin/main (${BEHIND} commit(s) on main not in dev)"
  local DEV_WT=""
  while read -r path _rest; do
    if [[ "$_rest" == *"[dev]"* ]] || [[ "$_rest" == *"[dev "* ]]; then
      DEV_WT="$path"
      break
    fi
  done < <(git worktree list)
  if [[ -z "$DEV_WT" ]]; then
    if [[ -d /var/www/dev/.git ]] || [[ -f /var/www/dev/.git ]]; then
      DEV_WT=/var/www/dev
    fi
  fi
  if [[ -n "$DEV_WT" ]]; then
    if [[ -n "$(git -C "$DEV_WT" status --porcelain)" ]]; then
      echo "  WARN: dev worktree dirty — skip auto-sync; run: git -C $DEV_WT merge origin/main && git push" >&2
      return 0
    fi
    git -C "$DEV_WT" checkout dev
    git -C "$DEV_WT" pull --ff-only origin dev || true
    git -C "$DEV_WT" merge origin/main -m "chore: sync dev with promoted main"
    if [[ "$DO_PUSH" -eq 1 ]]; then
      git -C "$DEV_WT" push origin dev
    fi
    echo "✓ dev synced @ $(git -C "$DEV_WT" rev-parse --short HEAD)"
  else
    # No worktree: push merge via temporary worktree
    local TMP2
    TMP2=$(mktemp -d)
    git worktree add "$TMP2" origin/dev
    git -C "$TMP2" merge origin/main -m "chore: sync dev with promoted main"
    if [[ "$DO_PUSH" -eq 1 ]]; then
      git -C "$TMP2" push origin HEAD:dev
    fi
    git worktree remove --force "$TMP2" 2>/dev/null || rm -rf "$TMP2"
    echo "✓ dev synced via temp worktree"
  fi
}

if [[ "$DO_PUSH" -eq 1 ]]; then
  sync_dev_with_main || true
fi

echo "  CI: Verify always runs on push; deploy only on main after Verify."
