# HTML → Godot migration checklist

Mirror of **[PARITY.md](./PARITY.md)** phases 0–8 (checkboxes).  
**Rollup status:** [`tools/port/PHASE_STATUS.md`](../tools/port/PHASE_STATUS.md) (canonical structure vs product).  
**Living product gaps:** [PARITY_RESIDUALS.md](./PARITY_RESIDUALS.md) · [DUAL_PRODUCT_FAIL_LIST.md](./DUAL_PRODUCT_FAIL_LIST.md).

Source of truth: `public/index.html` + `public/assets/`.  
Structure smoke: `npm run port:gates`. **Product gate: dual QA + PARITY Phase 7 sign-off.**

---

## Status legend (match PHASE_STATUS.md)

| Mark | Meaning |
| --- | --- |
| `[x]` under **Structure** | Wired + gate/unit/dual harness evidence |
| `[ ]` under **Product** | Eye-pass / E2E / density still open |
| `[x]` under **Product** | Product accepted for that row (or intentional HTML match) |

Do **not** treat structure `[x]` as full port. Full port = Phase 7 product sign-off in PARITY.md.

---

## Phase 0 — Foundation

**Structure:** structure · **Product:** product_partial

- [x] **Structure** Mandate documented in PARITY.md (HTML + assets only; no shortcuts)
- [x] **Structure** Dual report treated as living checklist (`npm run port:dual -- --full`)
- [x] **Structure** FPS root cause notes (llvmpipe probe documented)
- [ ] **Product** Dual product review complete (SOFT list empty or accepted)
- [ ] **Product** FPS profile on real GPU + web device

## Phase 1 — Performance

**Structure:** structure · **Product:** product_partial

- [x] **Structure** Fixed-step `SimClock` (`sim_frame` + `sim_time` + `tick` alias; 60 Hz)
- [x] **Structure** Menu / outfit preview: `BobinaDrawCache`
- [x] **Structure** In-game Bobina cache (`get_play_texture`, face bins; dash/bomb live)
- [x] **Structure** Stage bg amortize (`StageBgDrawCache`)
- [x] **Structure** Particle color batching in WorldDraw
- [x] **Structure** World / HUD / FX redraw throttle (partial tick gates)
- [ ] **Product** 60 FPS desktop target met (need GPU re-measure)
- [ ] **Product** ≥30–45 FPS web target met

## Phase 2 — Bobina animation

**Structure:** structure · **Product:** product_partial (S7)

- [x] **Structure** Expressions + blink in `drawBobina` (`port:gate:2` + dual faces)
- [x] **Structure** Dual poses / blink open-closed / breath ticks / poses 0–5
- [x] **Structure** Outfit menu continuous anims + full wardrobe dual (28 skins)
- [x] **Structure** GIF overlays wired (talk / confused / leek)
- [x] **Structure** Play-scale + HUD-mini expression duals
- [ ] **Product** Menu vs play lid/limb polish (S7)
- [ ] **Product** Talk-during-dialog + leekspin + maid dance eye-pass

## Phase 3 — Exhaustive visuals

**Structure:** structure · **Product:** product_partial (S4–S9, S5–S6)

- [x] **Structure** Dual harness: wep / melee / special + HTML pairs
- [x] **Structure** WorldDraw merges MeleeSystem.swipe_fx + SpecialSystem.fx

### Weapons
- [x] **Structure** All 10 weapons dual stills + drawPShot variants
- [ ] **Product** Visual sign-off (density/timing/HUD chrome)

### Specials
- [x] **Structure** All 11 specials dual stills; Sixth Sense slowmo pin
- [x] **Structure** Mech optionShot columns dual (S8 partial harness)
- [ ] **Product** Beam width / mech column length / tentacle density (S8)

### Melee
- [x] **Structure** Duals: katana / lash / scythe / hammer / claws
- [ ] **Product** Swipe arcs / slash-dash / charge FX

### Aura / movement / bomb
- [x] **Structure** Power aura/radiance + dash/focus/bomb/shield/rapid/vial/phase duals
- [ ] **Product** High-power color + bomb flash (S4)

### Powerups / consumables
- [x] **Structure** Drop grid dual; all consumable apply + CD; bubbles/stardust
- [ ] **Product** Item glyph font polish (S5)

### Bosses (visuals)
- [x] **Structure** 7 portraits + ape special/live/dialog + wynn hell duals
- [x] **Structure** Same-state loadout dual (power 6 / starter kit); freeze-all-bullets
- [ ] **Product** Live density/spread residual (S9); twin live; defeat feel
- [ ] **Product** Stage motif intensity under boss (S6)

### Enemies / stage / meta
- [x] **Structure** Elite / mumu / item grids; core flow; ends; meta menus duals
- [ ] **Product** Pause blur (S3); shop quotes (S2); title social (S11)
- [ ] **Product** Leekspin / maid dance easter eggs

## Phase 4 — Mechanics

**Structure:** structure · **Product:** product_partial

- [x] **Structure** Gate + units: power bleed, extends, magnet, sixth rates, clear-gate, consumable CD, emblem toast, twin/dash/bomb, gamepad map
- [x] **Structure** Graze counter + ring + unit; bullet SPD; body hit r; armed special index
- [x] **Structure** BossController patterns / specials / twins / HP scale
- [ ] **Product** Graze / shotLevel / familiars full matrix eye-pass
- [ ] **Product** All boss phases live play matrix
- [ ] **Product** ProgressStore cloud merge E2E
- [ ] **Product** Touch parity (safe-area / latency)
- [x] **Product** Autofire: intentional hold-only (HTML touch toggle not ported — documented)

## Phase 5 — Audio

**Structure:** structure · **Product:** product_partial (S10)

- [x] **Structure** SFX all 16 envelopes unit PASS
- [x] **Structure** Music bridge (YT inject) + soundgate session + COEP/visibility fixes
- [x] **Structure** Fullscreen on gate (touch/web)
- [ ] **Product** Music mute/volume cold-load + social tab (S10)
- [ ] **Product** Desktop music stream (currently silent without YT)

## Phase 6 — UI overlays & meta

**Structure:** structure · **Product:** product_partial (S1–S3, S11)

- [x] **Structure** Dual stills: settings, display, keybinds, help, pause, name entry, shoutouts, soundgate, touch, leaderboard
- [x] **Structure** Settings volume same-state dual + ScrollContainer full card (S1 partial)
- [ ] **Product** Settings copy/reset confirm polish (S1)
- [ ] **Product** Pause dim/blur vs Control chrome (S3)
- [ ] **Product** Title peephole + social strip (S11)
- [ ] **Product** Arsenal drag-drop, emblems filters, LB cloud highlight, shop buy FX

## Phase 7 — Dual QA hard gate

**Structure:** structure · **Product:** hold

- [x] **Structure** Core dual PASS; report at `tools/port/playtest_out/index.html`
- [x] **Structure** Full dual ran 2026-08-12 (pairs present; open FAIL duals closed F1–F8)
- [x] **Structure** FPS probe exists (llvmpipe — not product target)
- [ ] **Product** GPU + web FPS meet targets
- [ ] **Product** Progress + music verified on web export `/godot/`
- [ ] **Product** SOFT residuals accepted or closed (S1–S11)
- [ ] **Product** Written sign-off filled in PARITY.md Phase 7 log (not CUTOVER HOLD)

## Phase 8 — Cutover / Steam / OS

**Product:** blocked (until Phase 7 product sign-off)

- [ ] Web export + music patch + staging smoke
- [ ] `USE_GODOT=1` flip after approval
- [ ] Desktop export (no public/ HTML runtime)
- [ ] Steamworks (achievements, cloud, leaderboards, glyphs, art)
- [ ] Windows / macOS / Linux packaging + controller polish
- [ ] Final perf pass per target

## Explicit bans (must stay clean)

- [x] No `_draw_fast` / mini-Bobina / native-only entity art as final presentation
- [x] No gameplay iframe of `public/index.html`
- [x] No “complete” claim from `port:gates` or matrix COMPLETE alone
- [x] No `USE_GODOT=1` before Phase 7 **product** sign-off
