# Kill All Mumus — Godot 4.3 (modular)

Modular Godot port of **Bobina: Kill All Mumus!!**. The legacy single-file canvas game remains under `../public/` until HTML5 export is deployed.

## Layout

```
godot/
├── project.godot
├── data/                 # Pure data (JSON) — stages, weapons, emblems…
├── assets/textures/      # Art migrated from public/assets
├── autoload/             # Singletons: GameState, Progress, API, Config
├── scenes/
│   ├── main/             # Root Main.tscn
│   ├── player/
│   ├── enemies/
│   ├── bullets/
│   ├── ui/               # Title, HUD, Pause, Display, Settings, LB, End
│   └── shop/             # (reserved)
└── scripts/
    ├── player/
    ├── enemies/
    ├── combat/           # Bullet + pool
    ├── stages/
    ├── ui/
    ├── systems/          # (reserved: rank, shop, emblems helpers)
    └── net/              # (reserved: extra HTTP helpers)
```

## Run (desktop)

```bash
~/.local/godot/godot --path /var/www/killallmumus.com/godot
```

Needs `libfontconfig` for full GUI; headless import:

```bash
~/.local/godot/godot --path /var/www/killallmumus.com/godot --headless --import
```

## Export for killallmumus.com

1. Install Godot export templates (HTML5).
2. Export → Web → `../public_godot/` (or replace `public/` when ready).
3. Keep Express `server.js` for `/api/*` and Bobina OAuth.
4. Point nginx root / static to the export; proxy `/api` and `/auth` to Node.

## Backend

Unchanged Node API:

- `POST/GET /api/scores`
- `GET/PUT /api/progress`
- Bobina OAuth (`/auth/bobina`)

`ApiClient.gd` talks to `Config.api_base_url` (same-origin on web).

## Port status

| System | Status |
| --- | --- |
| Modular data (JSON) | Done |
| Title / pause / display / settings / LB UI | Scaffold playable |
| Player move + shoot + bomb | Done |
| Enemy waves + simple boss HP | Done |
| Stages 1–7 data | Done |
| Score / rank / NG+ / difficulty | Done |
| Emblem + progress cloud | Wired via ProgressStore + API |
| Full boss AI / specials / melee art | **Next** — add under `scripts/enemies/bosses/`, `scripts/player/` |
| Procedural Bobina outfits | **Next** — `scripts/player/BobinaSprite.gd` |
| Touch controls | **Next** — `scenes/ui/TouchControls.tscn` |

The canvas `public/index.html` remains the live production client until you cut over the Godot web export.
