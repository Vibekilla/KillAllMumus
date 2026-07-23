# Contributing / branch workflow

## Game client parity

**`public/index.html` is the source of truth.** Live defaults to the HTML client
until Godot is proven identical. See `godot/PARITY.md`.

## Branches (strict)

| Branch | Role | Commits allowed? |
| --- | --- | --- |
| `feature/*` | **Only place you commit work** | **Yes** |
| `dev` | Integration (PR merges only) | **No** — never `git commit` here |
| `main` | Live production (PR merges only) | **No** — never `git commit` here |

## Linear flow (no loops)

```
origin/dev
    │
    ▼  ./scripts/feature-branch.sh my-change
feature/my-change   ←── all commits happen here
    │
    ▼  ./scripts/ship-feature.sh
PR → merge into dev → delete feature/*
    │
    ▼  (when ready for live)
./scripts/promote-to-live.sh     # PR dev → main only
    │
    ▼
main (live)  ──CI──►  refresh dev = main (rollback mirror)
```

### Commands

```bash
# Start work (from a clean tree)
./scripts/feature-branch.sh short-name

# Commit only on feature/* (wrapper refuses dev/main)
./scripts/commit-on-feature.sh -m "feat: describe the change"
# or: git commit -m "…"  while on feature/* only

# Ship: push → PR into dev → merge → delete feature branch
./scripts/ship-feature.sh

# Later: promote integration to production (no feature branch required)
./scripts/promote-to-live.sh
```

### Rules for agents and humans

1. **Never** `git commit` or `git push` new commits on `dev` or `main`.
2. **Never** force-push `dev`/`main` except CI’s post-deploy “dev mirrors main”.
3. **Never** leave a merged `feature/*` on origin — `ship-feature.sh` deletes it.
4. One feature branch per change-set; cut again with `feature-branch.sh` for the next change.
5. Prefer `./scripts/commit-on-feature.sh` so accidental commits on `dev`/`main` fail.
6. Repo hook: `.githooks/pre-commit` (enabled by `feature-branch.sh` via `core.hooksPath`) blocks commits on `dev`/`main`.

### What `ship-feature.sh` does (and does not)

- **Does:** push `feature/*`, open/update PR → `dev`, merge, delete feature branch, checkout local `dev` to track origin (read tip only).
- **Does not:** commit on `dev`/`main`, force-push integration branches, leave orphan feature branches.

`--promote` on ship is optional shorthand for “after merge, also run promote-to-live”.

## CI

- Push to `feature/**` verifies the tree and ensures a PR into `dev` exists.
- Merge to `main` deploys live and refreshes `dev` as the rollback mirror.
- CI does not replace `./scripts/ship-feature.sh` for merge + branch delete.

## Godot 1:1 port

- No fallbacks/stubs for gameplay or draw code.
- `npm run port:inventory` — every `draw*` in `public/index.html` maps to Godot.
- Cutover still needs explicit `USE_GODOT=1` after parity sign-off.

## Rollback

Prefer `git revert` on `main` via a **feature branch** PR into `dev` then promote.
After deploy, `dev` already mirrors last good `main`.
