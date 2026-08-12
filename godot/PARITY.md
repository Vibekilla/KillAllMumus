
> **Status rollup (structure vs product):** [`tools/port/PHASE_STATUS.md`](../tools/port/PHASE_STATUS.md) — use tiers `structure` / `product_partial` / `product_ok` / `hold` / `blocked` only.  
> **Residuals:** [`PARITY_RESIDUALS.md`](./PARITY_RESIDUALS.md) · dual queue [`DUAL_PRODUCT_FAIL_LIST.md`](./DUAL_PRODUCT_FAIL_LIST.md).  
> **Checkboxes:** [`MIGRATION_CHECKLIST.md`](./MIGRATION_CHECKLIST.md).  
> **Export method:** `npm run export:godot` writes **dev** `public_godot/` and **mirrors live** `public_godot/` so both `/godot/` previews update (live `/` stays html-legacy until Phase 7).

# HTML → Godot parity (true 1:1 full port)

> **Source of truth** = `public/index.html` + `public/assets/`.  
> **Real status** = dual QA report + written Phase 7 **product** sign-off (not matrix COMPLETE).  
> **Phases 0–7 product** must be accepted before any **Phase 8** cutover, Steam, or OS expansion work begins.

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

**File exists ≠ ported.** Real status = **wired into draw path + same behavior + dual product eye-pass**.

### Structure vs product (short)

| Layer | Meaning | Typical evidence |
| --- | --- | --- |
| **structure** | Godot path wired; gate/unit/dual still exists | `port:gates`, matrix, dual harness |
| **product_partial** | Structure green; density/chrome/E2E open | Residuals, dual SOFT S1–S11 |
| **product_ok** | Slice accepted | Closed dual FAIL/SOFT |
| **hold** | Phase 7 product gate not signed | Sign-off log = CUTOVER HOLD |
| **blocked** | Phase 8 waiting on Phase 7 | USE_GODOT off |

As of 2026-08-12: **structure** largely green for Phases 0–7; **product** remains **product_partial** / Phase 7 **hold**. See `PHASE_STATUS.md`.

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
| 0.3 | Profile Godot desktop + web; document FPS root cause | **structure** + **product_partial** — llvmpipe notes; GPU/web open |

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
| 1.3 | World / HUD / FX: throttle redraws; keep CanvasCompat hot paths | **structure** — tick gates + StageBg cache; full-field cost residual |
| 1.4 | Target: 60 FPS desktop, ≥30–45 FPS web | **product_partial** — llvmpipe only; GPU/web re-measure open |

### FPS root cause notes (Phase 0.3 / 1)

Probe: `npm run port:fps` (Xvfb + Mesa **llvmpipe** software GL — not representative of real GPU).

| Scene | Wall ms/frame (llvmpipe) | Notes |
| --- | --- | --- |
| title | ~42 ms (~24 FPS) | title path after throttle (llvmpipe) |
| play | ~71 ms (~14 FPS) after hotpath; ~85 ms (~12 FPS) with mobs | llvmpipe only — GPU/web re-measure still open |

Code-path root causes (why ~7 FPS “throughout”):

1. **Renderer**: server probe / some hosts use **Mesa llvmpipe** (software GL) — not a real GPU.  
2. **`drawBobina` live** — 4k-line CanvasCompat drawer; was falling through on cache miss every facing change.  
3. **WorldDraw PLAY at 60 Hz** — entire field rebuilt in GDScript polygons every sim tick.  
4. **StageBg live / dense re-bake** — full StageBgFx + SubViewport bake every few ticks.  
5. **Mitigations (2026-08-02)** — PLAY WorldDraw **30 Hz**; never live Bobina except dash/bomb (outfit/face fallback + stand-in); StageBg cache-only + solid cold path; Bobina `TICK_BUCKET_PLAY=8`, 1 bake/frame; StageBg `TICK_BUCKET=10`; gradient bands 12.  
6. **Still needed** — enemy bake/batch; real **GPU + web** FPS measure (Phase 1.4); optional further PLAY 20 Hz on low FPS.

```bash
npm run port:gates          # structure Phases 0–8
npm run port:fps            # wall-clock probe
npm run port:dual -- --full # product gate after cache changes
```

### Phase 2 — Core character animation (Bobina)

Exact HTML timing and pixels:

| # | Requirement | Status |
| --- | --- | --- |
| 2.1 | Breath, head bob, body sway, movement-driven leg kick + arm swing | **structure** + **product_partial** — formulas dualed; lid polish open |
| 2.2 | Blink: `(tick % 230) < 7 and not squee` | **structure** (dual open/closed) |
| 2.3 | Expressions `smile` / `uwu` / `giggle` / `annoyed` / `squee` (eyes/mouth/blush/brows/iris at every scale) | **structure** — menu ×4.7 + play ×1 + HUD-mini ×0.46 |
| 2.4 | Every outfit continuous animation (tails, wings, veils, tendrils, …) | **structure** + **product_partial** — 28 skins menu dual; product eye-pass open |
| 2.5 | Full pose system + victory-face mapping + `hold` prop + GIF overlays (`talk`, leekspin, confused) | **structure** + **product_partial** — dual wired; dialog/leek product open |

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
| 4.1 | Combat numbers: power bleed 0.00085, graze, extends, shot levels, weapon matrix, options/familiars, specials, melee charge, bombs, dash | **structure** + **product_partial** — units green; full matrix eye-pass open |
| 4.2 | Boss mechanics — all phases, patterns, HP, threat, specials, twins, defeat across every stage | **structure** + **product_partial** — BossController + dual stills; live matrix open |
| 4.3 | Item / burn / floater systems, consumables hold-to-use, emblem tick / unlock | **structure** + **product_partial** |
| 4.4 | Stage flow: intro → waves → clear gate → shop → dialog → next / win | **structure** + **product_partial** |
| 4.5 | ProgressStore (local + cloud), arsenal / shop, emblems, heads, estats — persist across refresh | **structure** + **product_partial** — cloud E2E open |
| 4.6 | Input: keyboard, gamepad, touch (exact HTML feel) | **structure** + **product_partial** — GamepadMap + touch chrome; latency product |
| 4.7 | Fire input unified (hold shoot / LMB / touch hold) — no separate autofire toggle (Steam/mobile/desktop same) | **product_ok** intentional |

### Phase 5 — Audio

| # | Requirement | Status |
| --- | --- | --- |
| 5.1 | All HTML `sfx()` envelopes (shoot/hit/kill/graze/item/power/extend/bomb/hurt/card/win/slash/whip/thud/boom/claw/warp) | **structure** — `SfxSynth` 1:1; melee `snd` wired |
| 5.2 | Music bridge: soundgate → lofi, mute, volume | **structure** + **product_partial** — web YT + SoundGate; cold-load E2E (S10); desktop no stream |

### Phase 6 — UI overlays & meta

Settings, Display, Keybinds, Help, Pause, Name Entry, Shoutouts, Soundgate, touch chrome, leaderboard + cloud merge.

| Area | Status |
| --- | --- |
| Settings / Display / Pause | **structure** + **product_partial** (S1/S3) |
| Keybinds + gamepad glyphs | **structure** + **product_partial** — key · pad labels, joy rebind |
| Help | **structure** + **product_partial** — HelpCanvas dual |
| Shoutouts | **structure** + **product_partial** |
| Name entry / leaderboard | **structure** + **product_partial** |
| Soundgate + touch chrome | **structure** + **product_partial** |
| Title social / peephole | **structure** + **product_partial** (S11) |

### Phase 7 — Full dual QA hard gate (“port complete”)

> **Matrix Phase 7 (62 UI/render/modals functions)** signed COMPLETE in `PARITY_FUNCTION_MATRIX.md` (2026-08-12) via `test_phase7_parity`. That is **not** this dual-QA product gate.


Fresh dual report covering **every** system in Phases 2–6, including:

- All weapons, specials, melee (radii/arcs/charge FX), auras, powerups, variants  
- All boss visuals + mechanics  
- Full Bobina animation set  
- Stage flow, HUD, particles, GIFs, menus  

| Gate | Status |
| --- | --- |
| Dual report harness | **structure** — full dual ran; open dual FAILs closed (F1–F8) |
| Dual product eye-pass | **product_partial** — SOFT S1–S11 + residual density |
| FPS verified (desktop + web targets) | **product_partial** — llvmpipe only; GPU + web open |
| Progress + audio verified | **product_partial** — music cold-load / cloud E2E open |
| **Written product sign-off** | **hold** — PROOF GREEN / CUTOVER HOLD; not full port |

**Only after product sign-off is the game considered fully ported.** Phase 8 remains **blocked**.

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

# Web export → always this repo's public_godot/ (dev worktree)
npm run export:godot
# live receives public_godot only via ./scripts/promote-to-live.sh
# USE_GODOT=1 on live only after Phase 7 sign-off
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
| 2026-08-12 | Grok (automated proof run) | `npm run port:dual -- --full` 236.8s · report `tools/port/playtest_out/index.html` sha256 `513a7e6f24bd116b…` · HTML 109 / Godot 162 / pairs 100 · pixel sample 23 OK / 1 SOFT / 0 DRIFT · unit P2–P7 + combat clocks PASS · `port:gates` 0–8 PASS · FPS llvmpipe title~16.5 / play~12.4 | **PROOF GREEN / CUTOVER HOLD** — dual+units ok; GPU FPS + music/cloud E2E + residual eye-pass still open before `USE_GODOT=1` |

---

## Git / promote

Work on **`dev`** (`/var/www/dev`), promote with `./scripts/promote-to-live.sh`.  
Do **not** enable `USE_GODOT=1` until Phase 7 sign-off above is filled in.
