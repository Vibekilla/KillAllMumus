# HTML → Godot parity (Steam-bound full port)

## Goal

A **complete** Godot 4 port of Bobina: Kill All Mumus — same game as
`public/index.html` (assets, audio, draw, combat, UI, input, meta). End state:

| Phase | Runtime | Flags |
| --- | --- | --- |
| **Now (porting)** | Live = HTML; Godot at `/godot/` / `?test` | `USE_GODOT` **off** by default |
| **Cutover** | Live = Godot WASM | `USE_GODOT=1` only after sign-off |
| **Steam** | Desktop Godot export (no browser HTML client) | No `public/` runtime dependency |

Do **not** remove dual-client routing or delete `public/index.html` until the
Godot client is proven 1:1 and cutover is intentional.

## Source of truth (during port)

**`public/index.html`** + **`public/assets/`** define every behavior and pixel.

Port rule: **no stubs, no simplified stand-ins, no lazy shortcuts.** Each
HTML `draw*` / `update*` / system maps to GDScript that implements the same
logic. Inventory:

```bash
npm run port:inventory   # tools/port/ELEMENT_INVENTORY.json
npm run port:gates       # phase gates P0–P9
npm run port:dual        # HTML + Godot screenshots (fast)
npm run port:dual -- --full
```

## Dual visual QA (optimized)

```bash
# Fast (~parallel HTML Playwright + Godot Xvfb shots)
npm run port:dual

# Full (outfits, power, longer sim)
npm run port:dual -- --full

# One side only
npm run port:dual -- --html-only
npm run port:dual -- --godot-only
```

Report: `tools/port/playtest_out/index.html`  
Godot shots need **Xvfb** for real GL (`xvfb-run`); pure `--headless` has no
viewport texture.

Scene smoke (no images):

```bash
godot --path godot --headless --script res://scripts/tools/playtest_run.gd
```

## Draw order (must match HTML `draw()`)

1. Stage background + boss ambience → **`WorldCanvas`** (Node2D, under entities)  
2. Entities (Bobina, mumus, bullets) → **Playfield** / BulletPool  
3. FX → **FxLayer**  
4. Panel / toasts / pause / touch → **HudCanvas** (CanvasLayer UI)  
5. Title / menus → **TitleScreen** etc.

Never draw full-field stage bg on a high CanvasLayer over the playfield —
that hid all entities.

## Pipeline

```bash
node tools/port/full_extract.mjs
node tools/port/js_to_gd.mjs          # drafts only — must be fixed to 1:1
node tools/port/sync_exact_client.mjs # assets mirror when needed
npm run port:inventory
npm run port:gates
npm run port:dual -- --fast
# After visual+mechanic sign-off:
KEEP_GODOT_WASM=1 godot --path godot --headless --export-release Web ../public_godot/index.html
# USE_GODOT=1 only then
```

## Steam path (later)

1. Finish web parity + cutover confidence.  
2. Godot **desktop** export (Linux/Windows/macOS) from the same project.  
3. Steamworks / builds via `godot-export-builds` patterns — no HTML5 shell required.  
4. Drop dual-client server flags when desktop is the product; web can stay WASM.

## Do not

- Ship approximate Godot as default while visuals/systems diverge  
- Remove `USE_GODOT` / `/godot/` dual path before full conversion  
- Force-reset `dev` from `main` after deploy (wipes integration WIP)  

## Git (simple)

Work on **`dev`** (`/var/www/dev`), promote to **`main`** for live:

```bash
cd /var/www/dev
git commit -am "feat: …" && git push origin dev
./scripts/promote-to-live.sh   # when ready for production
```

See `CONTRIBUTING.md`.
