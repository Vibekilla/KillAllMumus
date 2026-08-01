# HTML → Godot migration checklist

Mirror of **[PARITY.md](./PARITY.md)** phases 0–7 (checkboxes only).  
Policy, bans, and cutover narrative live in PARITY.md — not here.

Source of truth: `public/index.html` + `public/assets/`.  
Structure smoke: `npm run port:gates`. **Product gate: dual QA + PARITY Phase 7 sign-off.**

---

## Phase 0 — Foundation

- [ ] Mandate documented in PARITY.md (HTML + assets only; no shortcuts)
- [ ] Dual report treated as living checklist (`npm run port:dual -- --full`)
- [ ] FPS profile written (desktop + web root cause)

## Phase 1 — Performance

- [x] Fixed-step `SimClock` (`sim_frame` + `sim_time` + `tick` alias; accumulator; `Engine.physics_ticks_per_second=60`)

- [x] Menu / outfit preview: cache full `drawBobina` (SubViewport bake — `BobinaDrawCache`)
- [x] In-game Bobina cache (`get_play_texture`, face bins, stale-frame fallback; dash/bomb live)
- [x] Stage bg amortize (`StageBgDrawCache` — PF bake of gradient + motifs + StageBgFx)
- [x] Particle color batching in WorldDraw
- [x] World / HUD / FX redraw throttle + CanvasCompat hot paths (partial — tick gates)
- [ ] 60 FPS desktop target met (llvmpipe probe still low; need GPU re-measure)
- [ ] ≥30–45 FPS web target met

## Phase 2 — Bobina animation

- [x] Structure: expressions + blink period in `drawBobina` (`port:gate:2`)
- [x] Dual face shots: Auto / :3 / Smile / squee / Giggle / Annoyed
- [x] Dual pose shots: idle / dance / cheer
- [x] Dual blink open vs closed (SimClock tick window)
- [x] Blink formula ported: `(tick % 230) < 7 and not squee`
- [x] Dual breath ticks (idle 0 vs 35)
- [x] Dual all poses 0–5 (incl. coffee / This Is Fine hold + fire)
- [x] Dual continuous outfit anims in **outfits menu** (angel/succubus/voidling/honeypot/bride/empress/cabal @ 8 & 48)
- [x] GIF overlays: talk (dialog), confused (floater), leek (stage clear); AssetBank on SimClock
- [x] Full wardrobe dual via **OUTFITS menu** (HTML `drawOutfits` ×4.7 stage — all 28 skins)
- [x] Outfit menu chrome parity: gradient panel, radial spotlight, round-rect clip
- [x] Play-scale (×1) expression dual (`godot_play_face_0..5` via player dual_expr)
- [x] Pause card: full dim, center, hide HUD, 92vh height clamp
- [x] Smile lid stroke dampened at ×4.7 preview (anti-glasses)
- [x] HUD-mini (~0.46) expression dual on leaderboard (`godot_hud_face_0..5`)

## Phase 3 — Exhaustive visuals

- [x] Dual harness: `godot_wep_*` / `godot_melee_*` / `godot_special_*` + HTML pairs
- [x] WorldDraw merges MeleeSystem.swipe_fx + SpecialSystem.fx into draw path

### Weapons
- [x] spread (Emblem Amulets) — dual `godot_wep_spread` + HTML drawPShot gold ellipse
- [x] laser (Red Death) — dual; crimson roundRect bolt (not multi-arc)
- [x] homing (Monke Bananas) — dual + yellow ellipse
- [x] wave (Jungle Vines) — dual + green ellipse
- [x] scatter (Bobo Bear Claws) — dual + brown pellet
- [x] gatling (Gatling Lasers) — dual + green bolt
- [x] grenade (Grrnade Launcher) — dual + fuse spark
- [x] voidripper — dual + purple rift
- [x] lotus (Lotus Petals) — dual + pink petal
- [x] shock (Shock & Awe) — dual + zap stroke
- [x] Dual combat re-run: 0 triangulation errors (pill round_rect + tri guards)
- [ ] Product visual sign-off vs HTML dual report (petal density/timing, HUD chrome)

### Specials
- [x] Structure duals for all 11 keys (`godot_special_*` harness)
- [x] Sixth Sense: full `drawSlowmoFx` (clock hands + vignette) + dual pin mid-timer
- [ ] Product visual sign-off vs HTML (laser beam, mech escort, etc.)

### Melee
- [x] Structure duals: katana / lash / scythe / hammer / claws
- [ ] Product visual sign-off swipe arcs / slash-dash

### Aura / movement / bomb
- [x] Power aura + radiance duals (`godot_aura_power_*`)
- [x] Dash / focus / bomb / shield / rapid / vial / phase duals
- [ ] Product visual sign-off (aura color parity at high power)

### Powerups / consumables
- [x] Drop types dual grid path
- [x] All consumable apply paths (tap-to-use + 3s CD; HTML hardened)
- [x] bubbles / stardust FX spawn + update
- [ ] Product visual sign-off item icons / floater chrome

### Bosses (visuals)
- [x] Structure duals: all 7 portraits + ape special/live/dialog + wynn hell (`godot_boss_*`)
- [x] Dual harness: full power aura, player lower third, boss @ HTML y+140
- [x] FlowUI: clear redraw on dialog dismiss (no ape-dialog bleed onto later bosses)
- [x] AlchemistTheOG (ape) — portrait dual
- [x] Dr. Robotnik — portrait dual
- [x] Mumina — portrait dual
- [x] Lily — portrait dual
- [x] India Police — portrait dual
- [x] Bogdanoff twins (Igor / Grichka) — portrait dual
- [x] James Wynn (+ hell portal dual)
- [ ] Product visual sign-off (stage bg motifs, minions, detailed art polish)
- [ ] Intro / specials / phases / dialog / defeat / hell portal / twin swap / ambience (live play)

### Enemies / stage / meta
- [x] Elite grid dual (`godot_elites_grid` — cheer/ape/badnik/pup/scammer/voideye/goon)
- [x] Mumu grid dual (`godot_mumus_grid` — lil/big ± icy)
- [x] Item drop grid dual (`godot_items_grid`)
- [ ] Product visual sign-off (item glyph font polish, stage motifs)
- [ ] Intro / dialog / shop + Honey Badger / stage-clear + leekspin + maid dance
- [ ] Win / game-over / clear portal / full HUD / particles / floaters / emblem toasts
- [ ] Title + peephole + social + every meta-menu live preview

## Phase 4 — Mechanics

- [x] Structure smoke (`npm run port:gate:4`) — CombatHelpers / Fire / StageFlow / ProgressStore
- [x] Power bleed 0.00085 (`test_power_bleed`)
- [x] Extends / kill-extend (`test_extend`)
- [x] Item magnet / collect line (`test_item_magnet`)
- [x] Sixth Sense slowmo rates (`test_slowmo_sixth`)
- [ ] Graze, shot levels, weapon matrix, familiars full product pass
- [ ] Specials / melee charge / bombs / dash numbers match HTML
- [ ] All boss phases, patterns, HP, threat, twins, defeat
- [ ] Items / burns / floaters / consumables / emblem tick product pass
- [ ] Stage flow: intro → waves → gate → shop → dialog → next / win
- [ ] ProgressStore local + cloud; arsenal/shop; emblems; heads; estats persist
- [ ] Keyboard / gamepad / touch parity
- [ ] Autofire setting

## Phase 5 — Audio

- [ ] All 16 `sfx()` envelopes
- [ ] Music bridge (soundgate → lofi; mute; volume)

## Phase 6 — UI overlays & meta

- [ ] Settings
- [ ] Display
- [ ] Keybinds
- [ ] Help
- [ ] Pause
- [ ] Name entry
- [ ] Shoutouts
- [ ] Soundgate
- [ ] Touch chrome
- [ ] Leaderboard + cloud merge

## Phase 7 — Dual QA hard gate

- [ ] Fresh `npm run port:dual -- --full` covers Phases 2–6 systems
- [ ] Dual report reviewed (`tools/port/playtest_out/index.html`)
- [ ] FPS verified (desktop + web)
- [ ] Progress + audio verified on web export / `/godot/`
- [ ] Written sign-off filled in PARITY.md Phase 7 log

## Phase 8 — Cutover / Steam / OS (blocked until Phase 7)

- [ ] Web export + music patch + staging smoke
- [ ] `USE_GODOT=1` flip after approval
- [ ] Desktop export (no public/ HTML runtime)
- [ ] Steamworks (achievements, cloud, leaderboards, glyphs, art)
- [ ] Windows / macOS / Linux packaging + controller polish
- [ ] Final perf pass per target

## Explicit bans (must stay clean)

- [x] No `_draw_fast` / mini-Bobina / native-only entity art as final presentation
- [x] No gameplay iframe of `public/index.html`
- [x] No “complete” claim from `port:gates` alone
- [x] No `USE_GODOT=1` before Phase 7 sign-off
