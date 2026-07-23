# HTML → Godot parity (true 1:1 full port)

> **Source of truth** = `public/index.html` + `public/assets/`.  
> **Real status** = dual QA report + written sign-off.  
> **Phases 0–7** must be complete (including every weapon, special, melee radius/arc, animation, powerup, variant, aura, and boss visual/mechanical system) before any **Phase 8** cutover, Steam, or OS expansion work begins.

| Rule | |
| --- | --- |
| Source of truth | HTML + assets only |
| No placeholders | Full drawers for Bobina, mumus, bullets, bosses, menus |
| No “fast” art | No `_draw_fast`, mini-Bobina stand-ins, native-only entity blobs |
| No wrappers | No iframe/WebView of `index.html` for gameplay |
| Same font | **Trebuchet MS** shipped (`godot/assets/fonts/TrebuchetMS*.ttf`) |
| Same assets / SFX | All IMG keys, GIF frame anims, 16 `sfx()` types |
| Same menus + overlays | Canvas states **and** DOM overlays (settings, pause, help, …) |
| Live | HTML until **Phase 7** dual QA sign-off (`USE_GODOT` off) |

**File exists ≠ ported.** Real status = **wired into draw path + same behavior + dual QA**.

---

## Asset pipeline (daily workflow)

Tools live at repo root (`npm run port:*`). Use them so nothing is left behind.

### A. Inventory HTML source of truth

```bash
npm run port:inventory    # public/ assets + index references
npm run port:extract      # functions + data tables → tools/port/extracted/
```

Diff extract output against `godot/data/` and keys referenced by drawers / WorldDraw.

### B. Sync & verify static assets

```bash
npm run port:sync         # mirrors public/assets → godot/assets (+ exact client helpers)
npm run port:verify       # critical map / presence gate
```

- After every sync: file-presence (+ hash when possible) so AssetBank cannot miss a key.
- **`AssetBank.gd` is the single lookup.** Any live draw site that hard-codes a path or falls back to a placeholder is a parity failure.

### C. GIF / animated sequences

- Sequences: `confused`, `talk`, `leekspin` (and clear-art statics).
- Confirm frames under `godot/assets/` and that Godot timers match HTML frame timing.
- Dual screenshots of floaters, dialog overlays, stage-clear leekspin are the real test.

### D. Fonts & emoji

- Force **Trebuchet MS** everywhere; never let Noto silently replace UI text.
- Emoji / lock icons: Noto Color Emoji fallback for now; Steam target may ship a PNG icon atlas mapped to the same keys.

### E. Data tables

JSON under `godot/data/`: weapons, specials, melee, consumables, outfits, emblems, stages, bosses, ranks.

```bash
npm run port:extract      # re-run when HTML constants change
# then diff godot/data/
```

### F. Dual QA (asset + mechanic truth test)

```bash
npm run port:dual -- --full
# → tools/port/playtest_out/index.html
```

After **any** asset or drawer change, re-run dual and inspect the report. File presence alone is not enough.

### G. Hygiene

- Prefer extending `port:verify` / inventory so it lists: keys referenced in drawers, files on disk, missing / unused.
- Structure smoke `npm run port:gates` ≠ visual parity. Dual QA is the product gate.

---

## Naming convention (HTML → Godot)

Public draw entry points use **HTML camelCase** exactly (`drawBobina`, `drawOutfits`, `drawStageClear`, `poseParams`, …).

- Drawers: `func drawBobina(...)` in `drawBobina.gd` (same for other `draw*.gd`)
- `PortedDraw`: thin host that exposes the same names and dispatches to drawers — no snake_case twin API
- Menu modules (`draw_menus.gd`, `draw_flow.gd`, `draw_hud.gd`): public `func drawX` matches HTML; private helpers may use `_snake_case` per GDScript practice
- CanvasCompat: canvas-style API may use snake_case helpers (`draw_image`, `begin_path`) as a Canvas2D adapter, not HTML game functions

## Modular Godot structure (keep this)

```
godot/
  autoload/          # Config, GameState, FontBank, ProgressStore, AssetBank, …
  scripts/
    html_parity/     # SimClock, WorldDraw (orchestrator)
    render/
      CanvasCompat.gd
      drawers/       # drawBobina, drawMumu, drawPShot, drawTitle, … (1:1 modules)
    combat/ enemies/ player/ systems/ ui/ audio/
  data/              # JSON tables from HTML constants
  assets/textures + fonts
```

- **WorldDraw** = single presentation pass (HTML `draw()` playfield body), one shared `CanvasCompat`.
- **Entity nodes** = simulation + collision only (`_draw` empty).
- **Drawers** stay separate modules — never collapse into one megascript; never replace a drawer with a circle.
- Performance comes from **structure** (shared ctx, caches, tick-throttled redraw), not art downgrade.

---

## Phases 0–8 (exhaustive)

### Phase 0 — Foundation

| # | Requirement | Status |
| --- | --- | --- |
| 0.1 | Mandate in this file: HTML + assets only; no shortcuts | active |
| 0.2 | Dual report is the living checklist | active |
| 0.3 | Profile Godot desktop + web; document FPS root cause | **partial** — see FPS notes below |

### Simulation clock (fixed step — always)

HTML is **tick-driven**. Godot keeps the same determinism via `SimClock` (autoload):

| API | Role |
| --- | --- |
| `SIM_DT` / `HZ` | `1/60` fixed step (HTML sim frame) |
| `sim_frame` | Integer frame index — use for `% 230` blink, thrash, dual QA |
| `sim_time` | Seconds (`sim_frame * SIM_DT`) — sines / breath / continuous anim |
| `tick` | **Alias** of `sim_frame` (legacy drawers + playtest) |
| `alpha` | Display leftover toward next step (optional render interp) |
| `sim_tick(dt)` | Signal — wire combat / FX / stage / power bleed here |

Rules: **no** pure variable-`delta` combat; **no** wall-clock inside sim; rendering free-runs.

### Phase 1 — Performance (blocks all visual polish work)

| # | Requirement | Status |
| --- | --- | --- |
| 1.1 | Menus / outfit previews: cache complex drawers (esp. full `drawBobina`) into SubViewport / bake on state change | **done** — `BobinaDrawCache` + outfit stage bake |
| 1.2 | In-game Bobina: same caching for outfit + expression + pose | **done** — `get_play_texture` + face bins; dash/bomb live |
| 1.3 | World / HUD / FX: throttle redraws; keep CanvasCompat hot paths | **partial** — WorldDraw 20 Hz shop/clear/intro, 6 Hz pause; HUD 30 Hz; PLAY 60 Hz entities; **StageBgDrawCache** amortizes bg+fx (~15–20 Hz bake) |
| 1.4 | Target: 60 FPS desktop, ≥30–45 FPS web | **open** — probe on llvmpipe software GL; re-measure on GPU / web |

### FPS root cause notes (Phase 0.3 / 1)

Probe: `npm run port:fps` (Xvfb + Mesa **llvmpipe** software GL — not representative of real GPU).

| Scene | Wall ms/frame (llvmpipe) | Notes |
| --- | --- | --- |
| title | ~73 ms (~14 FPS) | full title draw path |
| play | ~299 ms (~3.3 FPS) baseline before StageBg cache | WorldDraw + entities + Bobina |

Code-path root causes:

1. **Full `drawBobina` every redraw** — primary cost (menus ×4.7, play every tick).  
2. **WorldDraw single pass** — full field each sim tick on PLAY (correct for parity).  
3. **Title** — tick-throttled (~30 Hz idle).  
4. **Mitigations landed** — `BobinaDrawCache` for menus + play (face-bucketed); **`StageBgDrawCache`** PF bake for stage bg/motifs/fx; shop/stage-clear/intro WorldDraw 20 Hz; pause 6 Hz; HUD 30 Hz; particle color batch.  
5. **Still needed** — enemy sprite batching, measure on hardware GPU / web (Phase 1.4).

```bash
npm run port:gates          # structure Phases 0–8
npm run port:fps            # wall-clock probe
npm run port:dual -- --full # product gate after cache changes
```

### Phase 2 — Core character animation (Bobina)

Exact HTML timing and pixels:

| # | Requirement | Status |
| --- | --- | --- |
| 2.1 | Breath, head bob, body sway, movement-driven leg kick + arm swing | **partial** — formulas in `drawBobina`; dual breath ticks 0/35 |
| 2.2 | Blink: `(tick % 230) < 7 and not squee` | **done** (structure + dual open/closed) |
| 2.3 | Expressions `smile` / `uwu` / `giggle` / `annoyed` / `squee` (eyes/mouth/blush/brows/iris at every scale) | **partial** — all faces dual; multi-scale matrix still open |
| 2.4 | Every outfit continuous animation (tails, wings, veils, tendrils, …) | **partial** — full 28 skins dual on **outfits menu** ×4.7; anim ticks on wing/tail skins |
| 2.5 | Full pose system + victory-face mapping + `hold` prop + GIF overlays (`talk`, leekspin, confused) | **partial** — faces/poses/hold via outfits menu; talk/confused/leek dual |

### Phase 3 — Exhaustive visual systems

Must all be dual-matched.

**Weapons (projectile visuals + trails + glow)**  
spread (Emblem Amulets), laser (Red Death), homing (Monke Bananas), wave (Jungle Vines), scatter (Bobo Bear Claws), gatling (Gatling Lasers), grenade (Grrnade Launcher), voidripper, lotus (Lotus Petals), shock (Shock & Awe).

**Specials (full FX sets)**  
laser (Kraken Cannon), mech (SKOL Mech), bearzooka, vault (Emblem Vaults), stampede (Jungle Stampede), badger (Honey Badger), sixth (Sixth Sense), revenge (Ourbie’s Revenge), kiss (Kiss Me), kraken (Unleash the Kraken), void (Call of the Void).

**Melee (reach / arc / charge FX)**  
| Id | Reach ~ | Arc ~ | Signature FX |
| --- | --- | --- | --- |
| katana (Kuma Katana) | 155 | 2.0 | plasma-flame field |
| lash (Kraken Lash) | 225 | 1.25 | chain lightning |
| scythe (Ourbie’s Scythe) | 150 | 2.7 | green black hole |
| hammer (Vault Hammer) | 165 | 3.1 | shockwave fling |
| claws (Badger Claws) | 130 | 2.3 | thousand-strike flurry |

Plus swipe arcs, weapon models, slash-dash.

**Aura / power / movement**  
Power aura, power radiance, dash comet, slash-dash, focus vacuum, invuln flash, shield / rapid / vial / phase, Bobina Blast bomb clear.

**Powerups / items / consumables (capsule + icon)**  
power, fullpower, point, life, bomb, shield, rapid, skull, honeycomb, bulltears, bullsouls, galaxygas, clover, bubbles, wagyu, stardust, vial, banana, wormhole + hold-to-use cooldown bars.

**Boss visuals (full)**  
AlchemistTheOG (ape), Dr. Robotnik, Mumina, Lily, India Police, Bogdanoff twins (Igor/Grichka), James Wynn (+ Devil if present) — portraits, bodies, intro, specials, phases, dialog, defeat, hell portal, twin swap, boss ambience.

**Enemy variants**  
All mumu base forms + elites (cheer, ape, badnik, pup, scammer, voideye, goon, …).

**Stage / meta visuals**  
Intros, dialog + portraits, shop + Honey Badger, stage-clear + leekspin + maid dance, win / game-over, clear portal/gate, full HUD, particles, score texts, emotes, burns, floaters, emblem toasts, title Bobina + peephole + social, every meta-menu live preview.

### Phase 4 — Exhaustive mechanical systems + bosses

| # | Requirement | Status |
| --- | --- | --- |
| 4.1 | Combat numbers: power bleed 0.00085, graze, extends, shot levels, weapon matrix, options/familiars, specials, melee charge, bombs, dash | open |
| 4.2 | Boss mechanics — all phases, patterns, HP, threat, specials, twins, defeat across every stage | open |
| 4.3 | Item / burn / floater systems, consumables hold-to-use, emblem tick / unlock | open |
| 4.4 | Stage flow: intro → waves → clear gate → shop → dialog → next / win | open |
| 4.5 | ProgressStore (local + cloud), arsenal / shop, emblems, heads, estats — persist across refresh | open |
| 4.6 | Input: keyboard, gamepad, touch (exact HTML feel) | open |
| 4.7 | Autofire setting | open |

### Phase 5 — Audio

| # | Requirement | Status |
| --- | --- | --- |
| 5.1 | All 16 `sfx()` envelopes | open |
| 5.2 | Music bridge: soundgate → lofi, mute, volume | open |

### Phase 6 — UI overlays & meta

Settings, Display, Keybinds, Help, Pause, Name Entry, Shoutouts, Soundgate, touch chrome, leaderboard + cloud merge.

### Phase 7 — Full dual QA hard gate (“port complete”)

Fresh dual report covering **every** system in Phases 2–6, including:

- All weapons, specials, melee (radii/arcs/charge FX), auras, powerups, variants  
- All boss visuals + mechanics  
- Full Bobina animation set  
- Stage flow, HUD, particles, GIFs, menus  

| Gate | Status |
| --- | --- |
| Dual report reviewed (`tools/port/playtest_out/index.html`) | open |
| FPS verified (desktop + web targets) | open |
| Progress + audio verified | open |
| **Written sign-off** (date + reviewer below) | **not signed** |

**Only after this sign-off is the game considered fully ported.**

### Phase 8 — Cutover, Steam & OS expansions

*(Only after Phase 7 is green)*

1. Fresh web export + music patch → staging smoke → flip `USE_GODOT=1`.  
2. Desktop export (no `public/index.html` runtime dependency).  
3. Steamworks: achievements (from emblems), cloud saves, leaderboards, controller glyphs, store art.  
4. OS expansions: Windows / macOS / Linux packaging, controller polish, display options.  
5. Final performance pass on each target.

### Long-term (post signed-off parity)

Keep simulation + data. Gradually replace presentation with native Controls / pre-baked variants / Particles + shaders while retaining CanvasCompat drawers as the dual-QA oracle.

---

## Explicit bans (must stay clean)

- `_draw_fast`, `_draw_mini_bobina`, “Fast path: native” entity art  
- Gameplay iframe of `public/index.html`  
- Claiming port complete from `port:gates` file-presence alone  
- Optimistic “close” language without dual evidence  
- `USE_GODOT=1` / Steam / multi-OS packaging before Phase 7 sign-off  

---

## Commands

```bash
# Asset + data
npm run port:inventory
npm run port:extract
npm run port:sync
npm run port:verify

# Structure smoke only (not product gate)
npm run port:gates

# Product gate
npm run port:dual -- --full
# open tools/port/playtest_out/index.html

# Desktop
~/.local/godot/godot --path /var/www/dev/godot

# Web export (after Phase 7 only for live cutover)
godot --path godot --headless --export-debug "Web" public_godot/index.html
./scripts/patch-godot-music.sh
```

### Flip live (Phase 8 only)

```bash
export USE_GODOT=1
# restart node service
curl -sS http://127.0.0.1:3000/api/health   # must report "client":"godot"
```

Rollback: `USE_GODOT=0` (or unset) + restart → html-legacy.

---

## Phase 7 sign-off log

| Date | Reviewer | Dual report hash / notes | Result |
| --- | --- | --- | --- |
| — | — | — | **not signed** |

---

## Git / promote

Work on **`dev`** (`/var/www/dev`), promote with `./scripts/promote-to-live.sh`.  
Do **not** enable `USE_GODOT=1` until Phase 7 sign-off above is filled in.
