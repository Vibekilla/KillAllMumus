# HTML → Godot residual gaps (living audit)

**Source of truth:** `public/index.html` + `public/assets/`  
**HTML surface:** ~298 top-level functions, ~70 `draw*` helpers  
**Godot surface:** ~128 `.gd` scripts; structure gates 0–8 PASS  
**Product rule:** dual/structure green ≠ product complete. Sign-off only after behavior + eye-pass.

---

## Method (every ship)

```bash
cd /var/www/dev
# 1) Fix against HTML
# 2) Export so BOTH previews update:
npm run export:godot
#    → /var/www/dev/public_godot
#    → rsync /var/www/killallmumus.com/public_godot
# 3) Test:
#    https://dev.killallmumus.com/           (Godot default)
#    https://dev.killallmumus.com/godot/
#    https://killallmumus.com/godot/         (preview; / stays html-legacy)
# 4) Dual / unit where applicable
# 5) Commit + promote for server.js / git main
```

Line-by-line: pick HTML function → find Godot → **diff behavior** → dual/test → export both → check off here.

---

## Phase 0 — Foundation residuals

| Gap | Detail |
|-----|--------|
| Dual as living checklist | Full matrix duals exist but product review incomplete |
| FPS root cause | Documented; llvmpipe only (~12.5 title / ~7.5 play). **GPU/desktop/web re-measure open** |
| Structure vs product | `port:gates` all PASS while many product gaps remain (this file) |

---

## Phase 1 — Performance residuals

| Gap | Detail |
|-----|--------|
| 60 FPS desktop target | Not verified on real GPU |
| ≥30–45 FPS web | Not verified on `/godot/` with real device |
| CanvasCompat cost | Shadow multi-ring, poly fill, gradient bands still heavy |
| WorldDraw throttle | Partial tick gates; full-field redraws remain |
| Stage bg / Bobina cache | Present; verify stale under outfit switch / dash / bomb |

---

## Phase 2 — Bobina animation residuals

| Gap | Detail |
|-----|--------|
| Product eye-pass | Expressions dualed; menu vs play scale lid/stroke still polish |
| `_frontArm` | **HTML intentional no-op** (`frontArm=(col,lw)=>{}`); Godot matches — not a gap |
| Pose props | coffee / This Is Fine fire — structure; edge timing product |
| GIF overlays | talk/confused/leek wired; talk during dialog product pass |
| Maid dance easter egg | Title idle 30s — structure present; product pass open |
| Leekspin | Stage clear asset map exists; product pass open |

---

## Phase 3 — Exhaustive visuals residuals

### Weapons
| Gap | Detail |
|-----|--------|
| Product sign-off | Structure duals for all 10; density/timing/power-level stills open |
| Familiar **optionOffsets** | **Fixed** HTML −16/16/0,14/0,−15 |
| Familiar **optionPos** | **Fixed** body-rotation map (FireSystem + fire.gd + drawOptions) |
| **drawOptions world pos** | **WAS drawing at 0,0** (local flag); **fixed** HTML `optionPos(player)` world coords |
| option_shot weapon match | **Fixed** FireSystem + legacy `drawers/fire.gd` now weapon-matched |

### Specials
| Gap | Detail |
|-----|--------|
| Product sign-off | Structure duals; mech escort / laser beam / kraken tentacles polish |
| Sixth Sense | drawSlowmoFx + rates unit PASS; product visual mid-run |

### Melee
| Gap | Detail |
|-----|--------|
| Swipe arcs | Structure duals; charge FX / dash-slash product |
| `drawMeleeWeapon` | Present; all 5 weapon prop poses product |

### Aura / FX
| Gap | Detail |
|-----|--------|
| Power aura / radiance | Dualed; high-power color product |
| Dash comet / phase veil | Wired; product |
| **drawStunStars** | **Wired** inline in WorldDraw (★ orbit when `e.stun>0`) |
| **drawEmote** | **Wired** WorldDraw `_draw_emote`; HTML `emote()` is still no-op by request |
| Burns / floaters | Partial; density product |
| Particles | Present; batching partial |

### Bosses
| Gap | Detail |
|-----|--------|
| Portrait duals | All 7 structure duals |
| **Minions** | HTML keeps wave mobs until monologue ends then `clearWaveMobs`. **Fixed:** no wipe at boss spawn; clear on introDlg end |
| **Boss HP** | Was missing `round(hp*(2.1+stage*0.07))` (~2× too low). **Fixed** + twin 0.6 pools + phases=3 |
| **Boss intro** | Missing startDialog + introDlg gate. **Fixed** entry y=PF.y-40, dialog, clearWave |
| Boss ambience / mandala | Partial (`drawBossAmbience`) |
| Hell portal / Wynn hell | Dual stills; live play product |
| Twin swap (Bogdanoffs) | Code paths; product dual open |
| **Devil** drawer | Exists; wiring/product when HTML shows Devil |
| Boss patterns/HP/threat | Live play open (not dual-stilled) |
| Dialog bleed | FlowUI clear-on-dismiss fixed; product taunt lines open |

### Enemies / items / stage
| Gap | Detail |
|-----|--------|
| Elite/mumu/item grids | Structure duals; stage motif intensity product |
| Item glyph fonts | ♥★✸ emoji vs HTML monospace product |
| Stage bg FX | Gradients/motifs; parity intensity open |
| Wave spawner variety | `spawnWaves` structure | **Fixed** big/elite HP, r=30, ELITE_KIND table, kill score |
| Kill estats double-count | was +2 per kill | **Fixed** (add_kill only) |

### Dual harness holes
| Gap | Detail |
|-----|--------|
| HTML outfit anim pairs | `menu_outfit_anim_*_a/b` HTML-only names; Godot uses `_8/_48` naming — report pairing may miss |
| `html_play_firing` | HTML-only; Godot uses `godot_play_power6` |
| HTML missing duals for | help, display, keybinds historically; now added on core |

---

## Phase 4 — Mechanics residuals

| System | Unit / structure | Product residual |
|--------|------------------|------------------|
| Power bleed 0.00085 | PASS | — |
| Extends / kill-extend | PASS | Score thresholds product |
| Item magnet / collect line | PASS | Edge cases vacuum |
| Sixth Sense rates | PASS | — |
| Twin / dash / bomb numbers | PASS | Visual dashLandExplosion product |
| **Enemy bullet SPD** | **Fixed** `(hard?1:0.8)*(1+stage*0.13)*threatMul` | `test_bullet_spd` PASS |
| **Armed special** | Was always specials[0] on fire | **Fixed** uses `armed_special` index |
| **Body hit radius** | e.r+8 | **Fixed** e.r+5 (HTML p.r=3+2) |
| Gamepad map | PASS | Glyph labels product |
| Consumable tap + CD | PASS | All 11 apply FX product |
| Emblem toast | PASS | Queue stacking product |
| Clear gate timing | PASS | Visual portal |
| **Graze** | Counter + ring + emblems + test | **Structure PASS** (`test_graze.gd`); product eye-pass open |
| **shotLevel / powerCap** | Exists | Matrix vs HTML at each power product |
| **optionOffsets / optionPos** | **Fixed this ship** | Dual still re-verify |
| **Familiars fire weapon-matched** | FireSystem.option_shot | Confirm all 10 weapons |
| **Autofire** | Intentional hold-only | Document; no HTML touch toggle |
| Boss phases / AI | Large BossController | Live play matrix open |
| bossDmgMul / bossWepMul | Present + unit | **Fixed:** muls only on player shots; bomb/melee/special/dash raw (HTML) |
| eliteHearts | Present | Product |
| Cloud merge | ProgressStore paths | End-to-end product |
| Keyboard all binds | Map exists | Product |
| Touch multi-touch | JoyPad | Safe-area / latency product |

---

## Phase 5 — Audio residuals

| Gap | Detail | Status |
|-----|--------|--------|
| SFX 16 envelopes | Unit PASS | — |
| Soundgate every load | HTML re-shows; Godot session gate | Fixed (no permanent skip) |
| **Music blocked by COEP** | `require-corp` blocked YT iframe | **Fixed** (COEP only if threads; detector bug fixed) |
| MusicBridge retries | YT API ready race | Fixed |
| Export both trees | Dev + live public_godot | Fixed (`export:godot` mirror) |
| **Music dies on social / tab hide** | WebVisibilityPause soft-paused YT; autoplay blocked resume | **Fixed** — never pause lofi on visibility (HTML has no handler); `window.open` for social/LB/tweet; soft_resume nudge only on show |
| Music mute/volume product | Manual cold-load verify after fix | **Open (user verify)** |
| Desktop music | No YT | Silence unless local stream |
| initMaster / AudioContext | Resume on gate | Best-effort JS |
| OAuth login | same-tab navigate (music stops) | Intentional HTML parity |

---

## Phase 6 — UI / overlays residuals

| Overlay | Structure dual | Product residual |
|---------|----------------|------------------|
| Title | yes | Peephole, social strip, microcopy, auth chrome |
| Outfits | yes | Spotlight/clip/anim ticks |
| Arsenal | yes | Drag-drop / unequip product |
| Emblems | yes | Pages / filters product |
| Leaderboard | yes | Cloud fetch / mine highlight product |
| Settings | yes | Copy / reset inventory confirm product |
| Display | yes (restyled) | Section hints / prefs persistence product |
| Keybinds | yes | Rebind flow / gamepad product |
| Help | yes | Full tab content product |
| Pause | yes | Blur vs dim; HTML crops secondary buttons in dual |
| Name entry | yes | Focus / save / skip product |
| Shoutouts | yes | Content product |
| Soundgate | yes | Landscape CSS grid 1:1; music product verify |
| Touch chrome | yes | Safe-area, cycle btn, hit sizes |
| Shop | yes | Buy FX, tab focus, leave flow |
| Stage clear | yes | Leekspin, rank line product |
| Win / GO | yes | Share, NG+ banner product |
| **drawPanelTouch** | thin | Mobile panel layout product |
| **DOM vs Control** | mixed | Some overlays Control, some canvas — click routing edge cases |

---

## Phase 7 — Dual QA residuals

| Gap | Detail |
|-----|--------|
| Full `port:dual -- --full` | Core/combat slices green; full wardrobe+all combat night run open |
| Report review | `tools/port/playtest_out/index.html` must be human-reviewed |
| FPS GPU | Only llvmpipe numbers exist |
| Web music verify | After COEP fix — manual |
| Written Phase 7 log | `PARITY.md` sign-off empty |
| **USE_GODOT live** | Still banned until sign-off |

---

## Phase 8 — Cutover residuals (blocked)

| Gap | Detail |
|-----|--------|
| USE_GODOT=1 live | After Phase 7 only |
| Steam / desktop / multi-OS | Blocked by policy |
| Final perf per target | Open |

---

## Explicit incomplete / stub inventory (code)

| Location | Issue |
|----------|--------|
| `drawBobina._frontArm` | **HTML no-op (resolved)** |
| `ItemSystem.emote` | `pass` — matches HTML `/* emotes removed by request */`; draw path ready |
| `JoyPad.update_touch_buttons` | `pass` (special ready badge) |
| `draw_hud.drawPauseOverlay` | `pass` (PauseMenu Control owns pause) |
| `CanvasCompat` lineDash / lineJoin / textBaseline | no-op or partial |
| `CanvasCompat` gradients | Banded approximation not true canvas gradients |
| Entity `_draw` empty | Presentation via WorldDraw (intentional) |

---

## HTML `draw*` without 1:1 Godot module name

Present via other modules or partial — still product-check:

`drawOptions` (CombatFx), `drawDashComet`, `drawPhaseVeil`, `drawPowerRadiance`, `drawBossAmbience`, `drawMaidDance`, `drawStunStars` **(wired)**, `drawEmote` **(wired; spawn no-op)**, `drawFloater`, `drawBurns`, `drawShareBtn`, `drawMeleeWeapon`, `drawPanelPortrait`, `drawPanelTouch`, `drawHeart`, `drawOutfitFigure`, `drawPosedFigure`, `drawPoseProp`, `drawMenuBtn`, `drawTitleBtn`, `drawDevil`

---

## Priority backlog (next prompts)

1. **Manual music verify** social links keep lofi after hard-refresh  
2. **Familiar dual still** at power 2–6 (drawOptions world fix — re-shot)  
3. **Title social + peephole product**  
4. **Boss live pattern product eye-pass** (HP/intro structure fixed)  
5. **GPU FPS probe**  
6. **Full dual --full** + fill Phase 7 log  

---

## Changelog of residual discovery

| Date | Note |
|------|------|
| 2026-08-01 | Initial living list after phase 3–6 structure duals |
| 2026-08-01 | Music: soundgate session + COEP root cause + export mirror |
| 2026-08-01 | Deep audit: 298 HTML fns; optionOffsets/optionPos mismatch fixed; stun/emote missing; _frontArm no-op; dual naming holes |
| 2026-08-01 | Music cut-off: stop YT pause on visibility; open_url helper; fire.gd option_shot; stun/emote/_frontArm resolved |
| 2026-08-01 | Boss keeps wave minions (HTML parity); graze structure test |
| 2026-08-01 | Boss HP 2.1 scale + introDlg/clearWave; drawOptions world optionPos |
| 2026-08-01 | Boss take_damage: shot muls only (bomb was under-damaging at high power) |
| 2026-08-01 | Enemy bullet SPD mul (NORMAL 0.8 · HELL×NG threat) was hard-coded 1.0 |
| 2026-08-01 | Big/elite HP + ELITE_KIND table + single kill score/estats path |
| 2026-08-01 | Stage bullet SPD * (1+stage*0.13); armed special index; body hit r+5 |
| 2026-08-01 | Bomb silent kills; special_25 + bomb sfx; loadStage field clear (fx/burns/slowmo) |
| 2026-08-01 | bulletCancelAll/Near point drops + shell keep; neutralizeInputs on intro/shop |
| 2026-08-01 | Melee charge: flame 78 life, no double-hit; BH projectile; shockwall/flurry; melee cancel points |
| 2026-08-01 | Elite body-check uses eliteHearts(); melee mkills/mweps emblems + hit sparks |
| 2026-08-01 | Shock zap chain on hit; nade boom shake; grenade thud sfx |
| 2026-08-01 | Pshot vs enemy bullet score/point drops; focus hit ring; wormhole shake |
| 2026-08-01 | Bullet cancel split: death/slash/nade/explode pure despawn (no free points); specials soft-cancel; win emblem list cap |
| 2026-08-01 | loadStage: bombs floor 2 + initPlayer each stage; shield/rapid preserve; mouse_follow default 0.6 |
| 2026-08-02 | Boss body knock (vx 4.5 + knock 6 + hit sfx); dash offx/offy mouse resume; dash window 15; mouse speed keyboard-only |
| 2026-08-02 | Vault wave hit-once (5/14) + annulus cancel; bull/badger speeds+dmg; tentacle thrash; flurry knock/sfx; screen shake draw; stageclear arsenal |
| 2026-08-02 | Servitor hunt AI + bullet soak; laser beam cancel/radius; bombdrop boss 6 + shake; mech optionShot weapon-match |
| 2026-08-02 | Blackhole: launch settle 16f, boss chip 3 no-pull, bullet spiral devour (not clear_near) |
| 2026-08-02 | Vault hammer flung flight+wall detonate; clear-gate BEYOND/title labels + shop 🍯 |
| 2026-08-02 | Wynn hell portal hell_r/hy/scale wiring; lotus curl 0.03/life 62; shock spread+spd |
| 2026-08-02 | Melee swap: armed_melee index (HTML player.melee) not arsenal reorder; clamp on apply |
| 2026-08-02 | Blank playfield: WorldDraw parse fail on hy_v := ternary (no set type) — explicit float types + load-guard test |
| 2026-08-01 | Lotus curl/life HTML; stageclear introTimer=120; focus ring already shipped |
