# Kill All Mumus — Godot 4.3 port

Modular Godot port of **Bobina: Kill All Mumus!!**.

## Policy (read first)

> Source of truth = `public/index.html` + `public/assets/`.  
> Real status = dual QA report + written sign-off.  
> **Do not enable `USE_GODOT=1`, Steam packaging, or multi-OS ship work until Phase 7 is signed off in [PARITY.md](./PARITY.md).**

Live production serves the HTML client until that gate. Godot for dual review: `/godot/` or `?test` with `USE_GODOT` still off.

## Documents

| Doc | Role |
| --- | --- |
| **[PARITY.md](./PARITY.md)** | Single process truth — phases 0–8, asset pipeline, bans, sign-off |
| **[MIGRATION_CHECKLIST.md](./MIGRATION_CHECKLIST.md)** | Checkbox mirror of phases 0–7 |

## Layout

```
godot/
├── PARITY.md
├── MIGRATION_CHECKLIST.md
├── data/                 # JSON tables from HTML
├── assets/textures + fonts
├── autoload/
├── scenes/
└── scripts/
    ├── html_parity/      # SimClock, WorldDraw orchestrator
    ├── render/drawers/   # 1:1 HTML draw* modules
    ├── combat/ enemies/ player/ systems/ ui/ audio/
    └── tools/            # screenshot / dual helpers
```

## Port tooling (from repo root)

```bash
npm run port:inventory   # HTML asset / reference inventory
npm run port:extract     # functions + data from index.html
npm run port:sync        # assets → godot/assets (+ sync helpers)
npm run port:verify      # presence / critical map gate
npm run port:gates       # structure smoke only — not product gate
npm run port:dual -- --full
# → tools/port/playtest_out/index.html
```

## Run desktop (dev)

```bash
~/.local/godot/godot --path /var/www/dev/godot
```

## Web export (Phase 8 cutover only for live)

```bash
godot --path godot --headless --export-debug "Web" public_godot/index.html
./scripts/patch-godot-music.sh
# USE_GODOT=1 only after Phase 7 sign-off
```
