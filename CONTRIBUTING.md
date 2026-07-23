# Contributing / branch workflow

## Game client parity

**`public/index.html` is the source of truth.** Live defaults to this HTML client
so players always get the exact original game. See `godot/PARITY.md`.

## Branches

| Branch | Role |
| --- | --- |
| `main` | **Live production only** |
| `dev` | Integration + **rollback baseline** (refreshed after successful main deploys) |
| `feature/*` | One change-set, **always cut from `dev`** |

## One cohesive flow (no leftover branches)

```bash
# 1. Cut feature from latest dev
./scripts/feature-branch.sh my-change-name

# 2. Work + commit (conventional subjects: feat: / fix: / chore:)
git commit -m "feat: describe the change"

# 3. Ship: push → PR into dev → merge → delete feature branch
./scripts/ship-feature.sh

# Production when ready:
./scripts/ship-feature.sh --promote   # also merges dev → main (live)
# or run --promote only after several features are on dev
```

`ship-feature.sh` is the **only** end-of-feature entrypoint:

1. Pushes the current `feature/*` branch  
2. Opens or updates the PR **→ `dev`**  
3. Merges the PR  
4. Deletes the feature branch (local + remote)  
5. With `--promote`: merges `dev` → `main` (live deploy)

Do **not** leave merged feature branches on origin. Do not use separate ad-hoc
cleanup scripts — ship handles delete on merge.

Draft PR only (no merge): `./scripts/ship-feature.sh --draft`

## CI

On `feature/**` push, Actions also ensures a PR into `dev` exists (backup if
someone pushes without `ship-feature.sh`). Prefer always shipping via
`./scripts/ship-feature.sh` so merge + delete stay one step.

## Godot 1:1 port policy

- **No fallbacks / stubs** for gameplay or draw code.
- `npm run port:inventory` — every `draw*` in `public/index.html` must map to Godot.
- Canvas: `godot/scripts/render/CanvasCompat.gd` must match HTML canvas behavior.
- Live cutover still requires explicit `USE_GODOT=1` after parity sign-off.

## Rollback

```bash
# After main deploy, dev mirrors main. To re-ship last good intentionally:
git checkout main
git reset --hard origin/dev
git push --force-with-lease origin main
```

Prefer `git revert` on `main` when possible.
