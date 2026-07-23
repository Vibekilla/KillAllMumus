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
- [ ] Multi-scale expression matrix outside outfits menu (play ×1 / HUD mini) — separate from wardrobe dual

## Phase 3 — Exhaustive visuals

### Weapons
- [ ] spread (Emblem Amulets)
- [ ] laser (Red Death)
- [ ] homing (Monke Bananas)
- [ ] wave (Jungle Vines)
- [ ] scatter (Bobo Bear Claws)
- [ ] gatling (Gatling Lasers)
- [ ] grenade (Grrnade Launcher)
- [ ] voidripper
- [ ] lotus (Lotus Petals)
- [ ] shock (Shock & Awe)

### Specials
- [ ] laser (Kraken Cannon)
- [ ] mech (SKOL Mech)
- [ ] bearzooka
- [ ] vault (Emblem Vaults)
- [ ] stampede (Jungle Stampede)
- [ ] badger (Honey Badger)
- [ ] sixth (Sixth Sense)
- [ ] revenge (Ourbie’s Revenge)
- [ ] kiss (Kiss Me)
- [ ] kraken (Unleash the Kraken)
- [ ] void (Call of the Void)

### Melee
- [ ] katana ~155 / arc ~2.0 + plasma-flame
- [ ] lash ~225 / arc ~1.25 + chain lightning
- [ ] scythe ~150 / arc ~2.7 + green black hole
- [ ] hammer ~165 / arc ~3.1 + shockwave
- [ ] claws ~130 / arc ~2.3 + thousand-strike
- [ ] swipe arcs / models / slash-dash

### Aura / movement / bomb
- [ ] Power aura + radiance
- [ ] Dash comet + slash-dash + focus vacuum + invuln flash
- [ ] Shield / rapid / vial / phase
- [ ] Bobina Blast bomb clear

### Powerups / consumables
- [ ] power, fullpower, point, life, bomb, shield, rapid, skull
- [ ] honeycomb, bulltears, bullsouls, galaxygas, clover, bubbles
- [ ] wagyu, stardust, vial, banana, wormhole
- [ ] hold-to-use cooldown bars

### Bosses (visuals)
- [ ] AlchemistTheOG (ape)
- [ ] Dr. Robotnik
- [ ] Mumina
- [ ] Lily
- [ ] India Police
- [ ] Bogdanoff twins (Igor / Grichka)
- [ ] James Wynn (+ Devil if in HTML)
- [ ] Intro / specials / phases / dialog / defeat / hell portal / twin swap / ambience

### Enemies / stage / meta
- [ ] All mumu forms + elites (cheer, ape, badnik, pup, scammer, voideye, goon, …)
- [ ] Intro / dialog / shop + Honey Badger / stage-clear + leekspin + maid dance
- [ ] Win / game-over / clear portal / full HUD / particles / floaters / emblem toasts
- [ ] Title + peephole + social + every meta-menu live preview

## Phase 4 — Mechanics

- [ ] Power bleed 0.00085, graze, extends, shot levels, weapon matrix, familiars
- [ ] Specials / melee charge / bombs / dash numbers match HTML
- [ ] All boss phases, patterns, HP, threat, twins, defeat
- [ ] Items / burns / floaters / consumables hold-to-use / emblem tick
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
