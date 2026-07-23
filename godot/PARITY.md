# Full HTML → Godot parity policy

## Source of truth

**`public/index.html`** (~5430 lines, 290 functions) is the only pixel-perfect
game. Assets live under `public/assets/`.

Live production defaults to this client:

```bash
# server.js
USE_GODOT=1   # only when GDScript port passes visual+mechanic gate
# default: html-legacy from public/
```

## Why live is HTML right now

The modular Godot scaffolding (approximate fire patterns, simplified sprites,
Control-based menus) **is not** the original game. Shipping it as the default
violated “not a single thing different.”

Until the GDScript port is verified identical:

1. **Live = `public/`** (html-legacy)
2. **`public_godot/`** is kept as an **exact copy** of `public/` via  
   `node tools/port/sync_exact_client.mjs` (not a partial wasm build)
3. Godot project under `godot/` continues the true line-for-line port

## Port pipeline

```bash
# 1. Extract every function + data from public/index.html
node tools/port/full_extract.mjs

# 2. Mechanical JS→GD drafts (review required)
node tools/port/js_to_gd.mjs

# 3. Mirror assets + exact web client
node tools/port/sync_exact_client.mjs

# 4. Critical function map gate (when GD paths exist)
node tools/port/verify_parity.mjs

# 5. Only then: KEEP_GODOT_WASM=1 godot export + USE_GODOT=1
```

Extracted inventory: `tools/port/extracted/full_inventory.json`  
Reference script: `godot/assets/html/game_script.reference.js`

## What “done” means

Nothing different from `public/`:

| Layer | Must match |
| --- | --- |
| Assets | All 17 textures + icons, same pixels |
| Audio | Full `sfx()` oscillator table + YT lofi music |
| Draw | Every `draw*` including all outfit branches in `drawBobina` |
| Combat | `fire`, `update`, `updateBoss`, specials, melee, items, shop |
| UI | Title, shop, arsenal, emblems, outfits, NG, leaderboard, panels, touch |
| Input | Cursor follow, binds, joystick, pause overlays |
| Meta | Emblems, progress, scores API |

## Current GDScript status

- Data JSON: complete
- Combat systems: large parity pass (weapons/bosses/waves/specials/melee)
- Visuals: still incomplete vs canvas `drawBobina` / boss portraits / stage BG
- Audio: `SfxSynth.gd` ports HTML `sfx()` table
- Auto-port drafts: `godot/scripts/html_parity/ported/*.gd.txt` (290)

## Do not

- Ship approximate Godot as default while draw/audio/UI diverge
- Delete or replace `public/index.html` at all until explicitly instructed.
- Enable `USE_GODOT=1` without running the full visual checklist on all 7 stages
