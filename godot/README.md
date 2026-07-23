# Kill All Mumus — Godot 4.3 port

Modular Godot port of **Bobina: Kill All Mumus!!**.

## Critical policy

**`public/index.html` is the source of truth.**  
Live production serves that HTML client unless the GDScript port is proven
pixel- and mechanic-identical. See **[PARITY.md](./PARITY.md)**.

Do **not** export approximate Web builds over `public_godot/` without
`KEEP_GODOT_WASM=1` and a full parity sign-off. By default:

```bash
node tools/port/sync_exact_client.mjs   # public_godot/ = exact HTML copy
```

## Layout

```
godot/
├── PARITY.md
├── data/                      # JSON extracted from HTML (complete)
├── assets/textures/           # Full public/assets + icons
├── assets/html/               # Reference index + game_script
├── autoload/
├── scenes/
└── scripts/
    ├── combat/                # FireSystem, bullets, patterns
    ├── enemies/ + bosses/     # Waves + updateBoss patterns
    ├── systems/               # Specials, melee, shop, emblems
    ├── audio/SfxSynth.gd      # HTML sfx() oscillator table
    ├── render/                # CanvasCompat + PortedDraw
    └── html_parity/           # Full-canvas host + auto-port drafts
```

## Port tooling (repo root)

```bash
npm run port:extract    # all 290 functions + data
npm run port:convert    # JS → GDScript drafts
npm run port:sync       # assets + exact public_godot
npm run port:verify     # critical map gate
```

## Run desktop (WIP port)

```bash
~/.local/godot/godot --path /var/www/killallmumus.com/godot
```

## Export web (only after parity)

```bash
KEEP_GODOT_WASM=1 ~/.local/godot/godot --path . --headless \
  --export-release "Web" /var/www/killallmumus.com/public_godot/index.html
USE_GODOT=1   # in server env — do not enable until gate passes
```
