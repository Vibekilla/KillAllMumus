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
| S1 | Settings | Volume 100/90 dual fixed; HTML full-card shot + Godot ScrollContainer for Reset/Done |
| S2 | Shop | Random HB quote; LEAVE→stage clear improved |
| S3 | Pause / menus | Dim/blur; Control vs canvas chrome |
| S4 | Aura bomb | Same-state mid-window (bombFx=30, power 4, guest kit) dualed 2026-09-12; Godot still shows denser power-aura rings under the pink wash |
| S5 | Item glyphs | ♥★✸ emoji vs monospace feel |
| S6 | Stage bg intensity | Motif strength vs HTML psychedelia |
| S7 | Bobina lids/limbs | Menu vs play scale polish |
| S8 | Special density | **Laser beam 1:1 HTML gradient + 8px core** (2026-09-12); mech columns at live cadence (7×51px, 14 pshots). Residual: CanvasCompat banded gradient vs true canvas; bolt glow slightly lighter |
| S9 | Boss live patterns | **Harness PASS** — special 114 bullets + live 216 both sides; residual density/spread SOFT |
| S10 | Music E2E | Cold load + social tab product verify |
| S11 | Title social strip | Canvas chips vs HTML DOM #social residual |

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

---

## Next execution order

1. **S1/S3** Settings + pause chrome (pink thumbs shipped; % right-align + blur residual).  
2. **S8 residual** CanvasCompat true linearGradient (banded approx) + mech bolt glow.  
3. **S4 residual** Power-aura intensity under bomb wash.  
4. **S10** Music cold-load + social tab.  
5. **S11** Title social strip.  
6. GPU FPS — only then Phase 7 product sign-off discussion.
