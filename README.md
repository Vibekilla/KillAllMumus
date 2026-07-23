# Kill All Mumus

**Bobina: Kill All Mumus!!** — browser bullet-hell for [killallmumus.com](https://killallmumus.com).

They took her dad. Now she’s pissed. Save Bobina’s dad from the evil clutches of the LA Cabal.

| Layer | Tech |
| --- | --- |
| Game client | **Exact** canvas game `public/index.html` (source of truth) |
| Godot port | `godot/` — 1:1 port under phases 0–8; see `godot/PARITY.md` (Phase 7 dual sign-off before cutover) |
| API / static | Express (`server.js`) on `127.0.0.1:3000` |
| Database | PostgreSQL 17 (`bobina_scores` leaderboard) |
| Proxy | nginx → app (see `deploy/nginx/`) |
| Process | systemd **user** units (`scripts/install-user-services.sh`) |
| Backups | Daily `pg_dump` → parent dir `…/www-killallmumuscom/db-backups/` |

Live always serves the HTML client unless `USE_GODOT=1` **and** Phase 7 dual QA
is signed off in `godot/PARITY.md`. Do not ship approximate Godot to players.
Phases 0–7 (every weapon, special, melee, aura, boss, animation) must complete
before Phase 8 cutover / Steam / multi-OS work.

## Quick start (this server)

```bash
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh"
cd /var/www/killallmumus.com
cp -n .env.example .env   # if you still need secrets
npm ci
bash scripts/pg-start.sh
npm start
# → http://127.0.0.1:3000
```

Install persistent services (Postgres + app + 24h backup timer):

```bash
bash scripts/install-user-services.sh
# optional (keeps user services after logout):
#   sudo loginctl enable-linger "$USER"
```

## Database

- Cluster data: `~/.local/pgdata/killallmumus` (port **5433**, localhost only)
- App role/db: `killallmumus` / `killallmumus`
- Credentials: `.env` (`DATABASE_URL`) — **never commit**

```bash
npm run db:backup          # manual dump now
# automatic: systemd timer killallmumus-db-backup.timer (03:15 UTC daily)
```

### Backup storage contingencies

| Guard | Default |
| --- | --- |
| Refuse backup if free disk &lt; | `MIN_FREE_MB=1024` |
| Cap total backup size | `MAX_BACKUP_GB=5` |
| Always keep newest N dumps | `KEEP_MIN=3` |
| Age prune | `KEEP_DAYS=30` |
| Emergency | schema-only dump if no runway |

Backups directory (parent of the www worktree):

```
/home/vibekilla/.grok/worktrees/www-killallmumuscom/db-backups/
```

## Git / deploy model

- **`main` is always live** — production deploy runs from `main`.
- **`dev` is day-to-day work** — commit and push freely; promote when ready.
- **No required PRs / feature branches.** Optional personal branches are fine.
- Paths: live `/var/www/killallmumus.com` (`main`), work `/var/www/dev` (`dev`).

```bash
cd /var/www/dev
git pull && # edit…
git commit -am "feat: …" && git push origin dev
./scripts/promote-to-live.sh   # merge dev → main when ready for live
```

Workflow: `.github/workflows/deploy.yml` · details: `CONTRIBUTING.md`

## nginx (sudo once)

```bash
sudo cp deploy/nginx/killallmumus.com /etc/nginx/sites-available/
sudo ln -sfn /etc/nginx/sites-available/killallmumus.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/certbot
sudo nginx -t && sudo systemctl reload nginx
# after DNS:
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d killallmumus.com -d www.killallmumus.com
```

## API

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/api/health` | DB connectivity + score count |
| GET | `/api/scores` | Top 100 leaderboard |
| POST | `/api/scores` | Submit run (per-IP throttle, best-per-handle) |

## Bobina.moe login (OIDC)

Server implements Authorization Code + PKCE against `https://bobina.moe`:

| Route | Purpose |
| --- | --- |
| `GET /auth/bobina` | Start login |
| `GET /auth/bobina/callback` | OAuth callback |
| `GET /api/me` | Current session |
| `POST /auth/logout` | Clear session |
| `GET /auth/bobina/status` | Whether credentials are configured |

1. Register app on bobina.moe (**System → OAuth Apps**).
2. Redirect URI: `https://killallmumus.com/auth/bobina/callback`
3. Scopes: `openid profile social`
4. Put `BOBINA_CLIENT_ID` / `BOBINA_CLIENT_SECRET` in `.env`
5. `systemctl --user restart killallmumus`

Until credentials are set, anonymous play + X-handle leaderboard still work; Sign in shows a setup page.

## Godot modular client

The game is being ported to **Godot 4.3** under `godot/` (modular scenes/scripts/data).
Process truth: **`godot/PARITY.md`** (phases 0–8). Checklist: `godot/MIGRATION_CHECKLIST.md`.
Live serves `public/index.html` until **Phase 7** dual sign-off, then Phase 8 cutover.
See `godot/README.md`. Tooling: `npm run port:dual -- --full`, `port:sync`, `port:extract`.
