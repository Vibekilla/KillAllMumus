# Phase status — HTML → Godot (canonical rollup)

**Updated:** 2026-08-12  
**Canonical plan / bans / cutover:** [`godot/PARITY.md`](../../godot/PARITY.md)  
**Checkboxes:** [`godot/MIGRATION_CHECKLIST.md`](../../godot/MIGRATION_CHECKLIST.md)  
**Product gaps:** [`godot/PARITY_RESIDUALS.md`](../../godot/PARITY_RESIDUALS.md)  
**Dual SOFT/FAIL queue:** [`godot/DUAL_PRODUCT_FAIL_LIST.md`](../../godot/DUAL_PRODUCT_FAIL_LIST.md)  
**Function map (coverage only):** [`godot/PARITY_FUNCTION_MATRIX.md`](../../godot/PARITY_FUNCTION_MATRIX.md)

> **File exists ≠ ported.** Matrix COMPLETE ≠ product complete.  
> Product complete only after dual eye-pass + written Phase 7 sign-off in PARITY.md.  
> **Live client:** `USE_GODOT` **off** (html-legacy) until that sign-off.

---

## Status model (use these words only)

| Tier | Means | Evidence |
| --- | --- | --- |
| **unmapped** | No Godot home (or intentional platform wrapper only) | Matrix `unmapped` |
| **structure** | Wired into sim/draw path; gate and/or unit and/or dual harness present | `port:gates`, unit tests, dual still *exists* |
| **product_partial** | Structure done; density, chrome, live feel, or E2E still open | Residuals / dual SOFT |
| **product_ok** | Slice accepted by dual eye-pass (or intentional HTML match) | Closed FAIL/SOFT + note |
| **hold** | Phase-level product gate not signed | Phase 7 log |
| **blocked** | Waiting on prior phase | Phase 8 |

**Do not use “done” alone.** Always pair: `structure` and/or `product_*`.

```
structure green  →  code path + dual/unit exists
product_ok       →  human/product eye-pass accepted
Phase 7 hold     →  no USE_GODOT until product residuals + GPU FPS clear enough
```

---

## Phase rollup

| Phase | Scope | Structure | Product | Notes |
| --- | --- | --- | --- | --- |
| **0** | Foundation / dual as checklist | **structure** | **product_partial** | Docs + gates 0–8; dual living list active; FPS root cause documented (llvmpipe only) |
| **1** | Performance (cache, throttle) | **structure** | **product_partial** | Bobina + StageBg caches + tick gates; **GPU 60 / web ≥30–45 FPS open** |
| **2** | Bobina animation | **structure** | **product_partial** | Faces/poses/wardrobe dual; lids/breath/GIF/maid product polish (S7) |
| **3** | Exhaustive visuals | **structure** | **product_partial** | All wep/special/melee/aura/boss/enemy dual stills; density & chrome SOFT (S4–S9) |
| **4** | Mechanics + bosses + progress | **structure** | **product_partial** | Units green (bleed, graze, magnet, …); live boss matrix / cloud E2E / touch product open |
| **5** | Audio | **structure** | **product_partial** | 16 SFX unit PASS; YT bridge + soundgate structure; **music cold-load E2E open (S10)**; desktop no stream |
| **6** | UI overlays & meta | **structure** | **product_partial** | Dual stills for menus/flow; Control vs canvas chrome, social strip, shop polish (S1–S3, S11) |
| **7** | Dual QA hard gate + sign-off | **structure** | **hold** | Full dual ran; PROOF GREEN / **CUTOVER HOLD**; no written product sign-off |
| **8** | Cutover / Steam / OS | — | **blocked** | Blocked on Phase 7 product sign-off |

---

## Cross-doc map (what each file is for)

| File | Role | Completeness claim allowed? |
| --- | --- | --- |
| `PARITY_FUNCTION_MATRIX.md` | HTML function → Godot path; unit/structure phase checklists | **Coverage only** (“matrix COMPLETE”) — not product |
| `MIGRATION_CHECKLIST.md` | Per-item ☑ structure / ☐ product | Yes, with structure vs product lines |
| `PARITY_RESIDUALS.md` | Living product gap audit by phase | No “done” without closing residual |
| `DUAL_PRODUCT_FAIL_LIST.md` | Active dual FAIL/SOFT/HARNESS queue | Product dual truth for stills |
| `PHASE_STATUS.md` (this file) | One-page rollup | Must stay in sync with residuals + fail list |
| `PARITY.md` | Policy, bans, Phase 7 sign-off log | Sign-off only after product hold clears |
| `data/MIGRATION_STATUS.json` | Machine-readable migrated modules + open polish | Structure inventory only |

---

## Structure complete (do not re-litigate as “unported”)

These are **structure** green (2026-08-12):

- Data tables (stages, weapons, specials, melee, outfits, emblems, consumables)
- SimClock combat (fire, bullets, graze, power bleed, specials, melee, bomb, dash, items, bosses)
- Bobina draw path + face/wardrobe dual harness
- Weapon / special / melee / aura dual harness (all keys)
- Boss portraits (7) + special / live / dialog / wynn hell dual stills
- SFX 16 envelopes; soundgate + web music bridge structure
- UI shells duals (settings, display, keybinds, help, pause, shop, ends, touch, …)
- Matrix phases 2–7 function coverage COMPLETE (290 ported / 9 unmapped platform wrappers)
- `port:gates` 0–8 PASS

**Unmapped (intentional, not combat gaps):**  
`applyMe`, `bumpIdle`, `hookCloudSaves`, `loadMe`, `loginHref`, `paint`, `run`, `syncAccount`, `wrap`

---

## Product still partial (active work)

Primary queue → [`DUAL_PRODUCT_FAIL_LIST.md`](../../godot/DUAL_PRODUCT_FAIL_LIST.md):

| ID | Area | Structure | Product |
| --- | --- | --- | --- |
| S1 | Settings chrome | structure | product_partial |
| S2 | Shop quotes / leave flow | structure | product_partial |
| S3 | Pause dim/blur | structure | product_partial |
| S4 | Aura bomb flash | structure | product_partial |
| S5 | Item glyphs | structure | product_partial |
| S6 | Stage bg intensity | structure | product_partial |
| S7 | Bobina lids/limbs | structure | product_partial |
| S8 | Special density (beam/mech columns) | structure | product_partial |
| S9 | Boss live danmaku density | structure (harness PASS) | product_partial |
| S10 | Music cold-load + social tab | structure | product_partial |
| S11 | Title social strip | structure | product_partial |
| — | GPU + web FPS targets | structure (probe exists) | product_partial / open |

Open FAIL duals: **none** (F1–F8 closed). Phase 7 product sign-off: **hold**.

---

## Live / cutover

| Item | Status |
| --- | --- |
| `USE_GODOT` live | **off** — html-legacy |
| Phase 7 written sign-off | **hold** (PROOF GREEN / CUTOVER HOLD in PARITY.md) |
| Phase 8 Steam / multi-OS | **blocked** |

---

## Commands

```bash
# Structure smoke only
npm run port:gates

# Product gate (stills)
npm run port:dual -- --full
# → tools/port/playtest_out/index.html

# FPS (llvmpipe on server — not GPU truth)
npm run port:fps

# Asset sync
npm run port:inventory && npm run port:sync && npm run port:verify
```

---

## Next product queue (from fail list)

1. **S8/S4** — special/aura density (mech columns, laser beam width, bomb flash)  
2. **S1/S3** — settings + pause chrome  
3. **S10** — music cold-load + social tab  
4. **S11** — title social strip  
5. **GPU FPS** — then discuss Phase 7 product sign-off (still no USE_GODOT until signed)

---

## Changelog

| Date | Note |
| --- | --- |
| 2026-08-12 | Status model unified (structure / product_partial / product_ok / hold / blocked). Replaced stale “Phase 3 prep / phases 4–7 open” rollup. |
