# Kill All Mumus — Godot 4.3 (modular)

Modular Godot port of **Bobina: Kill All Mumus!!**.

## Layout

```
godot/
├── data/                 # JSON game data (stages, weapons, emblems, …)
├── assets/textures/      # Art
├── autoload/             # Config, GameState, Progress, API, Audio
├── scenes/               # Main, player, enemies, bullets, UI, shop
└── scripts/              # Matching modules (systems, combat, bosses, UI)
```

## Status

See `data/MIGRATION_CHECKLIST.md` — core systems migrated; HTML client retained as fallback when `public_godot/` is absent.

## Run desktop

```bash
~/.local/godot/godot --path /var/www/killallmumus.com/godot
```

## Export web

```bash
# templates: ~/.local/share/godot/export_templates/4.3.stable/
~/.local/godot/godot --path . --headless --export-release "Web" \
  /var/www/killallmumus.com/public_godot/index.html
```

Express serves `public_godot/` when present (`USE_GODOT=0` forces legacy `public/`).
