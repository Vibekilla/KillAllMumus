# HTML → Godot parity (Steam-bound full port)

## Goal

A **complete** Godot 4 port of Bobina: Kill All Mumus — same game as
`public/index.html` (assets, audio, draw, combat, UI, input, meta).

| Phase | Runtime | Flags |
| --- | --- | --- |
| **Now (porting)** | Live = HTML; Godot at `/godot/` / `?test` | `USE_GODOT` **off** by default |
| **Cutover** | Live = Godot WASM | `USE_GODOT=1` only after sign-off |
| **Steam** | Desktop Godot export | No `public/` runtime dependency |

Do **not** remove dual-client routing or `public/index.html` until cutover is intentional.

## Source of truth (during port)

**`public/index.html`** + **`public/assets/`**. No stubs / simplified stand-ins.

```bash
npm run port:inventory   # 68 draw* must stay mapped
npm run port:gates       # P0–P9
npm run port:dual -- --fast
```

## Architecture (current — keep)

| Layer | Node | Draws |
| --- | --- | --- |
| Stage bg + ambience | **WorldCanvas** (under playfield) | `draw_stage_bg`, boss ambience, veil, slowmo |
| Entities | Playfield / BulletPool | Bobina, mumus, bullets |
| FX | FxLayer | particles, melee arcs |
| HUD chrome | **HudCanvas** | panel, toasts, pause, touch — **not** stage bg |
| Menus | TitleScreen / FlowUI / EndScreen | title, outfits, arsenal, intro, shop |

Never put full-field stage bg on a high CanvasLayer (hid entities).

## Performance targets

- **60 FPS** sim + display (`run/max_fps=60`, vsync on).
- Redraw only when **SimClock tick** advances (title / HUD / world / Bobina).
- CanvasCompat: **cache font + FontBank**; avoid RegEx per `fill_text`.
- SFX: **AudioStreamWAV** bake (Web-safe), not live Generator push.

## Title menu 1:1 (HTML `drawTitle`)

Buttons (desktop):

1. Outfit row  
2. Mode + Leaderboard  
3. Arsenal · Emblems · Settings (+ NG+ if unlocked)  
4. Start pill  
5. Single-line control/info text (**no wrap**)

No HELP chip on the third row (HTML keeps help out of that row). Labels are single-line; button font shrinks to fit width.

## Phase gates (P0–P9) — status

| Gate | Scope | Status |
| --- | --- | --- |
| P0 | Inventory + HTML presence | PASS |
| P1 | Assets, layout 960×540, sfx types, input | PASS |
| P2 | Canvas menus + P2Meta | PASS |
| P3–P4 | Combat / specials | PASS |
| P5 | Items / FX | PASS |
| P6 | Stage flow / shop / portal | PASS |
| P7 | HUD panel + WorldCanvas bg split | PASS |
| P8 | Progress / emblems / consumables | PASS |
| P9 | Cloud + residual + USE_GODOT opt-in | PASS |

Gates assert **on-disk structure**. Visual/pixel QA still uses `port:dual`.

## Residual polish (not “unmapped functions”)

- Pixel-diff title/play vs HTML screenshots (fonts, spacing, peephole clip)
- Boss/elite pose polish under dual shots
- BGM if HTML adds music later
- Dual report copy Godot shots from app_userdata into `tools/port/playtest_out/`

## Git

Work on **`dev`** (`/var/www/dev`), promote with `./scripts/promote-to-live.sh`.
