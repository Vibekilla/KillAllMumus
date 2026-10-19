# Dual product fail list (living)

Honest side-by-side review. Dual harness green ≠ product parity.  
Update after each dual pass. Severity: **FAIL** / **SOFT** / **HARNESS**.

**Status model:** [`tools/port/PHASE_STATUS.md`](../tools/port/PHASE_STATUS.md)  
Open rows here = **product_partial** (or open harness lies). Closed FAIL ≠ full port.

Source dual: `tools/port/playtest_out/index.html` (regenerate with `npm run port:dual -- --full`).

---

## How to use

1. Fix highest FAIL first.  
2. Export + dual slice (`--shots weapons` etc.).  
3. Eye-pass stills + short live play.  
4. Mark closed with date.  
5. Only empty FAIL list (or accepted SOFT) → Phase 7 product sign-off.

---

## Open FAIL

| ID | Area | Evidence | Root cause / next fix |
|----|------|----------|------------------------|
| F1 | ~~**Weapons dual empty field**~~ | Was aura-only; re-dual → pshots present | **CLOSED** — sync freeze + aim nudge |
| F2 | ~~**Play state mismatch**~~ | power=1 score=0 + 6 lil both sides | **CLOSED** — forcePlayStill |
| F3 | ~~**Boss still loadout**~~ | power 6 / score 0 / starter kit | **CLOSED** — portraits + loadout same-state |
| F4 | ~~**Title dual guest chrome**~~ | 1/44, no NG+, guest auth | **CLOSED** |
| F5 | ~~**Outfit anim pair names**~~ | `_8`/`_48` | **CLOSED** |
| F6 | ~~**Mechanics / pickups HTML**~~ | paired | **CLOSED** |
| F7 | ~~**Special dual HUD**~~ | score/toasts cleared | **CLOSED** — residual density → S8 |
| F8 | ~~**Settings volume dual**~~ | was 50% vs 100% | **CLOSED** — dual forces music 100% · sfx 90% |

---

## Open SOFT

| ID | Area | Notes |
|----|------|-------|
| S1 | Settings | Expanded dual shows Reset, the HTML hint, Done, and the version line. 540p still pins that footer. Headless check: Done ends at y=417 and the version line at y=445 inside the 540 view (2026-10-18). Bear emoji stays tofu. Not export-played |
| S2 | Shop | Hint reads "LEAVE → stage clear" and leave returns to PLAY. Card strokes follow each item color. Descriptions wrap (8.5px was parsing as 5). 2026-10-13 shop still. Left/right browse is S13. Not export-played |
| S3 | Pause | Headless 540p: the card ends on Resume (bottom y=484) and Display starts below the clip. Scroll bar hidden; wheel still scrolls. Blur is sampled, not backdrop-filter. Not export-played |
| S4 | ~~Aura bomb scribble~~ | **CLOSED 2026-10-13** — soap bubble is on AddBack, BobinaPass covers it. Eye: bomb + power 3 show a readable Bobina inside the rings |
| S5 | Item glyphs | Pickups are bold-monospace P ★ ♥ ✸ ◈ » with textBaseline middle (2026-10-13 items still, aligned for fall). DejaVu raster differs from Chromium. Not export-played |
| S6 | Stage bg intensity | One shared loadStage roll (hue ±30, petals 3/5/7/9), including a new run that stays on stage 0. Headless test passes. Not export-played |
| S7 | Bobina lids/limbs | Outfit ×4.7 uses full HTML lineWidth scale (play keeps 0.96 AA shave) |
| S8 | Special density | Vertex-colored linear + radial rings (2026-09-13). Residual: true CanvasGradient vs sampled strips |
| S9 | Boss live patterns | step_n 48/100; live pins phases=1 so hp 55% does not trip phase-1 spiral. Do not copy phases=1 into BossController |
| S10 | Music E2E | Cold-load applyMusicVol + 6s YT retry. Source is shuffled playlist `PLC6gDrhD6E1X_mZ8arMGO48Ta-cpsnuzR` (the radio stream ended and cleared the tab audio icon). Live social-tab still a device check |
| S11 | Title sign-in | Pink "Sign in with Bobina" pill sits on the hint, above the chips (2026-10-13 core dual). Residual: no CSS gradient, letter-spacing .3px |
| S12 | ~~Melee slash~~ | **CLOSED 2026-10-13** — katana still shows the blade over the crescent. Extra inner stroke removed. CoverPass is above AddLayer |
| S13 | Shop keys / Escape | Arrows route only in the shop, leaderboard, and emblems. M is menu. Escape is not a binding. Not yet played on a fresh export |
| S14 | Clear gate | Leek is a border-box radius-10 tile. Banner clip is a rounded rect. Glow is the sampled shadow, not CSS box-shadow. Hut draws when the portal is null. Portal lighter stays omitted on purpose. Headless 2026-10-19: the void is a dark hole again (concentric rings; rim vertices were painting the outer stop) and the hut honey is a vector pot. Dual pair not re-shot. Not export-played |
| S15 | Boss death ring | WorldDraw now passes deadT into drawBoss. Not on a boss-death still yet |
| S16 | Shots and bullets | Laser bolts use roundRect capsules (rounded ends on the Godot still). HTML bolts had left the frame, so the pair is not same-position. Enemy outer disc replaced with shadowBlur 7; not on a bullet still |
| S17 | Ends HUD | Game-over dim shows the side HUD on both (2026-10-13 right-edge crop). Win photo is a rounded cover crop. Full end screen not export-played. Color emoji still tofu |

---

## HARNESS (not product art, but dual lies)

| ID | Issue | Fix |
|----|-------|-----|
| H1 | `play_firing` ↔ `play_power6` | Godot now also writes `godot_play_firing`; report prefers it |
| H2 | `boss_ape` ↔ `boss_ape_live` mixed | Report pairs `html_boss_ape_live` ↔ `godot_boss_ape_live` + special pair |
| H3 | Combat stills not same-state | Force power=6, clear field, fixed pos, freeze pshots |
| H4 | Pixel meanΔ false green | Different scores/saves dominate; use eye + behavior |
| H5 | Boss dual cleared bullets | **CLOSED** — special/live no longer `clear_all`; freeze all bullets |

---

## Closed (this campaign)

| Date | ID | Note |
|------|-----|------|
| 2026-08-12 | H1 partial | Alias `godot_play_firing` + report pair preference |
| 2026-08-12 | F1 closed | Re-dual weapons: laser/spread show shot columns (pshots logged) |
| 2026-08-12 | F2 closed | same-state play: 6 lil + power 1 + score 0 both sides |
| 2026-08-12 | F4 closed | title guest: emblems 1/44 + ngUnlocked=0 (no NG+ button) |
| 2026-08-12 | F5 closed | outfit anim dual names `_8`/`_48` both sides |
| 2026-08-12 | weapons density | dual volleys 4× with 26px aim nudge (less wall) |
| 2026-08-12 | F6 closed | HTML mechanics + pickups vacuum stills pair with Godot |
| 2026-08-12 | F7 partial | special duals clear score/toasts; dual_mode guest auth on title |
| 2026-08-12 | F8 closed | settings dual music 100% / sfx 90% both sides |
| 2026-10-13 | S4 closed | Aura bomb and power 3: Bobina readable inside the rings (AddBack + BobinaPass) |
| 2026-10-13 | S12 closed | Melee weapon draws on CoverPass above the lighter crescent |
| 2026-10-13 | S2 strokes | Shop cards stroke with each item's color |
| 2026-10-13 | S13 code | Shop left/right, leaderboard and emblem paging. Escape is not menu. M is menu |
| 2026-10-13 | S11 partial | Guest pill text, color, and y=452 match the HTML title still |
| 2026-10-13 | notes | Wardrobe and maid-dance notes rise (HTML `span - (base % span)`) |
| 2026-10-13 | S14 leek | Stage banner and leek are rounded rects. Border-box pink edge matches the still. Glow is sampled |
| 2026-10-13 | S5 glyphs | Monospace P ★ ♥ ✸ ◈ » with middle baseline. Not export-played |
| 2026-10-13 | S2 wrap | Shop blurbs wrap. 8.5px no longer parses as 5 |
| 2026-10-13 | S17 partial | Game-over dim shows the HUD. Win photo is a cover crop. Not export-played |
| 2026-10-18 | S6 code | Stage bg seeds roll once per loadStage on StageFlow; drawers and the bake cache share that roll |
| 2026-10-18 | S3 code | Pause fold ends on Resume at 540p; scrollbar hidden. Not export-played |
| 2026-10-18 | S1 code | Settings footer pin budgets card chrome and the wrapped hint. Bear emoji stays tofu |
| 2026-10-19 | S14 hole | Concentric radial rings. Headless core is a dark disc; honey is a vector pot. Not a dual close |
| 2026-10-18 | S14 harness | Core HTML shots now write `html_flow_cleargate`. Portal lighter stays off in Godot |
| 2026-10-13 | spotlights | Wardrobe cone matches the outfits still. Maid dance was not in that dual |
| 2026-08-12 | S1 scroll | SettingsMenu ScrollContainer + HTML .set-card element screenshot |
| 2026-08-12 | Boss dual PASS | typed-array loadout fix verified (7 bosses) |
| 2026-08-12 | F3 boss | clear toasts + starter Red Death; HTML pin clears unlock chrome |
| 2026-08-12 | S2 partial | Shop LEAVE → stage clear when `shop_return==stageclear` |
| 2026-08-12 | S9 harness | `forceBossSpecial` / `forceBossPattern` + Godot freeze-all-bullets; dual shows Diamond Hands + phase-0 danmaku |
| 2026-08-12 | S8 partial | Mech dual seeds optionShot columns + freeze pshots (was empty field) |
| 2026-08-12 | F3/F7 closed | residual art density stays SOFT |
| 2026-09-12 | S8 laser | HTML `createLinearGradient(-hw,0,hw,0)` + 8px core; CanvasCompat fillRect now transform-safe |
| 2026-09-12 | S8 mech | Guest kit + armed special; 7 volleys × 51px (HTML `ct%3` × laser spd 17) |
| 2026-09-12 | S4 bomb | Same-state bombFx=30 / power 4 / iframe 0 / guest specials |
| 2026-09-12 | S1/S3 thumbs | HSlider grabber Texture2D is HTML `#ff5b8d` (StyleBox grabber was ignored) |
| 2026-09-12 | S1/S3 chrome | Gold value spans, cyan Display/Controls, reset/done tints, overlay dim shader, follow 0.6 dual |
| 2026-09-12 | S8 glow | fillRect shadowBlur (HTML Red Death / optionShot); settings 540p shows How to Play |
| 2026-09-12 | S4 tick | dual_lock_tick=80 both sides for bomb still |

---

## Next execution order

Living queue is the Open SOFT table above. Do not treat a still as a close until a fresh `/godot/` export is played.

1. **S14** Same-run clear-gate still. The hole and the hut pot are headless-green. Leek glow is sampled, not a CSS gaussian.  
2. **S5 / S13 / S17** Play the fresh export. Glyph raster, shop keys, and the full end screens are still code-plus-still.  
3. **S1** 540p settings footer pin. Bear emoji stays tofu on this Godot.  
4. **S3** Pause scrollbar.  
5. **S6** Stage background seed. **S7** outfit lids. **S8** special density.  
6. **S10** Music cold-load. **S15** boss-death still.  
7. GPU FPS on this host is llvmpipe. Phase 7 stays **CUTOVER HOLD**. Do not set live `USE_GODOT`.
