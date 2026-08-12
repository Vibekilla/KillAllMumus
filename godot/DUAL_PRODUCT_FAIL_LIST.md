# Dual product fail list (living)

Honest side-by-side review. Dual harness green ≠ product parity.  
Update after each dual pass. Severity: **FAIL** / **SOFT** / **HARNESS**.

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
| F3 | **Boss still loadout** | power 6 / score 0 / no toast / starter kit | **Harness improved** — stills match better; **S9 live** still open |
| F4 | ~~**Title dual guest chrome**~~ | 1/44, no NG+, guest auth | **CLOSED** |
| F5 | ~~**Outfit anim pair names**~~ | `_8`/`_48` | **CLOSED** |
| F6 | ~~**Mechanics / pickups HTML**~~ | paired | **CLOSED** |
| F7 | **Special dual HUD** | score/toasts cleared | **Improved** — FX density SOFT |
| F8 | ~~**Settings volume dual**~~ | was 50% vs 100% | **CLOSED** — dual forces music 100% · sfx 90% |

---

## Open SOFT

| ID | Area | Notes |
|----|------|-------|
| S1 | Settings | Volume dual fixed (100/90); card crop (Controls/Help/Reset) vs HTML viewport still SOFT |
| S2 | Shop | Random HB quote; LEAVE→stage clear improved |
| S3 | Pause / menus | Dim/blur; Control vs canvas chrome |
| S4 | Aura bomb | Higher pixel Δ; flash timing |
| S5 | Item glyphs | ♥★✸ emoji vs monospace feel |
| S6 | Stage bg intensity | Motif strength vs HTML psychedelia |
| S7 | Bobina lids/limbs | Menu vs play scale polish |
| S8 | Special density | Beams/FX present; ring/particle density still differs |
| S9 | Boss live patterns | Dual still ≠ live danmaku feel |
| S10 | Music E2E | Cold load + social tab product verify |
| S11 | Title social strip | Canvas chips vs HTML DOM #social residual |

---

## HARNESS (not product art, but dual lies)

| ID | Issue | Fix |
|----|-------|-----|
| H1 | `play_firing` ↔ `play_power6` | Godot now also writes `godot_play_firing`; report prefers it |
| H2 | `boss_ape` ↔ `boss_ape_live` mixed | Report labels live ambience separately; keep |
| H3 | Combat stills not same-state | Force power=6, clear field, fixed pos, freeze pshots |
| H4 | Pixel meanΔ false green | Different scores/saves dominate; use eye + behavior |

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
| 2026-08-12 | S2 partial | Shop LEAVE → stage clear when `shop_return==stageclear` |

---

## Next execution order

1. **S9** Boss live pattern eye-pass (stage 1–2 dual tabs).  
2. **S8/S4** Special/aura particle density product.  
3. **S1/S3** Settings + pause chrome polish.  
4. **S10** Music cold-load + social tab.  
5. GPU FPS — only then Phase 7 product sign-off discussion.
