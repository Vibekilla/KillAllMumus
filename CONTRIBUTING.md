# Contributing / branch workflow

## Game client parity

**`public/index.html` is the source of truth.** Live defaults to this HTML client
so players always get the exact original game (assets, sounds, mechanics, canvas
drawing). See `godot/PARITY.md`.

```bash
# Extract + sync exact client / assets into godot + public_godot
node tools/port/sync_exact_client.mjs

# Godot web export only when 1:1 is verified:
# KEEP_GODOT_WASM=1  + godot --export-release Web
# USE_GODOT=1
```

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

## Feature branch lifecycle

1. Work on `feature/<name>` (source of truth for game client remains **`public/index.html`** until Godot cutover).
2. Open PR → review → **merge** to `main` or `dev`.
3. **Delete the branch** after successful merge:

```bash
scripts/branch-cleanup-after-merge.sh feature/<name> --base main
```

Do not leave merged feature branches on origin.

## Godot 1:1 port policy

- **No fallbacks / stubs / simplified stand-ins** for gameplay or draw code.
- Run `node tools/port/inventory_public.mjs` before claiming parity — every `draw*` in `public/index.html` must map to a Godot file.
- Canvas API lives in `godot/scripts/render/CanvasCompat.gd` and must match HTML fill/stroke/clip/text/emoji behavior.
