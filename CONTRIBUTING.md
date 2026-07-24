# Contributing / branch workflow

## Game client parity

**`public/index.html` is the source of truth** until Phase 7 dual QA sign-off
in `godot/PARITY.md`. Live defaults to the HTML client. Dual-client flags stay
until then — do not enable `USE_GODOT=1` or remove `/godot/` early.

## Branches (simple)

| Branch | Role | Commits |
| --- | --- | --- |
| `dev` | Day-to-day work + integration | **Yes — commit and push here** |
| `main` | Live production | **Yes when promoting** (or hotfixes) |

Feature branches and PRs are **optional**. Prefer direct commits on `dev`.

## Layout on this server

| Path | Branch | Purpose | Public URL |
| --- | --- | --- | --- |
| `/var/www/killallmumus.com` | `main` | Live tree | https://killallmumus.com (`:3000`) |
| `/var/www/dev` | `dev` | Active development | https://dev.killallmumus.com (`:3001`) |

```bash
cd /var/www/dev          # normal coding
# edit, commit, push origin dev
systemctl --user restart killallmumus-dev   # pick up server.js / public changes

cd /var/www/killallmumus.com   # live checkout (main)
./scripts/promote-to-live.sh   # merge dev → main and push live
```

### Dev site (`dev.killallmumus.com`)

- Service: `systemctl --user status killallmumus-dev` (Express on **3001**, tree `/var/www/dev`)
- Nginx: `deploy/nginx/dev.killallmumus.com` → install via `bash deploy/install-nginx-dev.sh`
- Env: `/var/www/dev/.env` with `PORT=3001`, `PUBLIC_ORIGIN=https://dev.killallmumus.com`, **`USE_GODOT=1`** (Godot default; HTML at `/legacy/`)
- Live stays **`USE_GODOT` off** (`html-legacy`) until Phase 7 sign-off
- DNS (GoDaddy): **A** record `dev` → this host; HTTPS via certbot
- Godot: `https://dev.killallmumus.com/` · HTML fallback: `/legacy/` · also `/godot/`

## Daily flow

```bash
cd /var/www/dev
git pull origin dev
# …edit…
git add -A
git commit -m "feat: describe the change"
git push origin dev
# or: ./scripts/push-dev.sh -m "feat: describe the change"
```

## Promote to live

When `dev` is ready for production:

```bash
./scripts/promote-to-live.sh
```

That fast-forwards or merges `origin/dev` into `main` and pushes `origin/main`.
CI on `main` restarts live services. **`dev` is not force-rewritten** after
deploy — your integration branch keeps its history.

## Optional helpers

```bash
./scripts/push-dev.sh -m "msg"   # commit (if dirty) + push origin/dev
./scripts/promote-to-live.sh     # merge dev → main + push main
./scripts/promote-to-live.sh --ff-only   # refuse non-ff merges
```

`feature-branch.sh` / `ship-feature.sh` remain as thin wrappers that print the
new workflow (no PR merge/delete dance).

## Rules

1. **Work on `dev`** in `/var/www/dev` (or any clone on branch `dev`).
2. **Live only from `main`** — promote deliberately.
3. Do **not** force-push `main` unless recovering a known-bad deploy.
4. Do **not** force-reset `dev` to `main` as a routine step (that deleted WIP).
5. Godot port: no stubs; follow `godot/PARITY.md` phases 0–8 (`USE_GODOT=1` only after Phase 7 sign-off).

## Rollback

```bash
# On main: revert the bad commit(s), push main
git checkout main
git revert <sha>
git push origin main
```

Or temporarily point live at a previous `main` SHA and push (with care).

## CI

- Push to `dev` or `main` runs verify (`node --check`, project files).
- Push to `main` deploys / restarts live (self-hosted runner).
- No required PR gates for feature branches.
