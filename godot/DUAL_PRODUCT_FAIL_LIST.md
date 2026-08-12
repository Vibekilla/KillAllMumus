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
| F1 | ~~**Weapons dual empty field**~~ | Was aura-only; re-dual `weapons,power6` → pshots 70–200 | **CLOSED 2026-08-12** — `_dual_freeze_pshots` sync + aim-nudge stream. Still SOFT: HTML toast chrome / score state differs |
| F2 | **Play state mismatch** | `html_play` early stage vs `godot_play` mid-fight | Harness: force same power/kills/score/tick for core play still |
| F3 | **Boss still loadout** | Boss duals different power/weapon/score than HTML | Same-state force for boss stills |
| F4 | **Title chrome** | Emblem count, NG+ row, social bar, auth layout differ | Progress bootstrap for dual + layout pass |
| F5 | **Outfit anim pair names** | HTML `_a/_b` vs Godot `_8/_48` | Align shot names in dual report |
| F6 | **Mechanics / pickups HTML missing** | Report has Godot-only mechanics & vacuum | Add HTML `__kamDual` stills for same states |

---

## Open SOFT

| ID | Area | Notes |
|----|------|-------|
| S1 | Settings | Volume defaults 50% vs 100%; icons; help button visible vs crop |
| S2 | Shop | Random HB quote; LEAVE hint (leave→stage clear) |
| S3 | Pause / menus | Dim/blur; Control vs canvas chrome |
| S4 | Aura bomb | Higher pixel Δ; flash timing |
| S5 | Item glyphs | ♥★✸ emoji vs monospace feel |
| S6 | Stage bg intensity | Motif strength vs HTML psychedelia |
| S7 | Bobina lids/limbs | Menu vs play scale polish |
| S8 | Special density | Mid-cast particle density product |
| S9 | Boss live patterns | Dual still ≠ live danmaku feel |
| S10 | Music E2E | Cold load + social tab product verify |

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
| 2026-08-12 | S2 partial | Shop LEAVE → stage clear when `shop_return==stageclear` |

---

## Next execution order

1. Re-dual **weapons + power6** only → verify F1 closed on stills.  
2. Same-state **core play** still (power/score/kills).  
3. Title dual bootstrap (emblems 0 or fixed).  
4. Live eye-pass: one full stage HTML vs Godot tabs.  
5. GPU FPS when art density is honest.
