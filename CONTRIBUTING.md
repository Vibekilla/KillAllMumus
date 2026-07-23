# Contributing / branch workflow

## Branches

| Branch | Role |
| --- | --- |
| `main` | **Live production only** |
| `dev` | Integration + **rollback baseline** (refreshed after successful main deploys) |
| `feature/*` | One change-set each, **always cut from `dev`** |

## Daily flow

```bash
# 1. Start work from latest dev
./scripts/feature-branch.sh my-change-name

# 2. Commit with feature notes in the subject
git commit -m "feat: add boss phase patterns for Bogdanoffs"
# or: fix: …  chore: …  docs: …

# 3. Push — CI verifies and opens/updates PR → dev
git push -u origin HEAD

# 4. Merge feature → dev after review
# 5. Promote dev → main (PR) when ready for production
# 6. After main deploy, CI force-updates dev = main for rollbacks
```

## PR overview

On every pull request, CI posts a concise **Overview** comment:

- Branch direction
- Feature notes (commit subjects)
- File stats
- Reminder that `main` is live and `dev` is the rollback mirror

Manual or agent-driven edits should still land via a **feature branch** and a conventional commit message so the overview stays useful.

## Rollback

```bash
# dev already points at last known-good main after deploy
git checkout main
git reset --hard origin/dev   # only if you intentionally re-ship the mirror
git push --force-with-lease origin main
```

Prefer `git revert` on main when possible.
