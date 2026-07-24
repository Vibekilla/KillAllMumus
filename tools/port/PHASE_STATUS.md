# Phase status — HTML → Godot true 1:1 port

**Canonical plan:** [`godot/PARITY.md`](../../godot/PARITY.md) (phases 0–8).  
**Checkboxes:** [`godot/MIGRATION_CHECKLIST.md`](../../godot/MIGRATION_CHECKLIST.md).

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Foundation / docs / dual as living checklist | **active** — docs + `port:gates` 0–8 |
| 1 | Performance (cache Bobina, throttle redraws) | **in progress** — Bobina cache + StageBg cache + particle batch; GPU/web FPS still open |
| 2 | Bobina animation (breath, blink, expressions, outfits, poses) | **done structure** — menu/play/HUD-mini dual; ready for Phase 3 |
| 3 | Exhaustive visuals (weapons / specials / melee / auras / powerups / bosses / meta) | **in progress** — dual harness + WorldDraw melee/special FX wire |
| 4 | Exhaustive mechanics + boss AI + stage flow + progress | **open** |
| 5 | Audio (16 sfx + music bridge) | **open** |
| 6 | UI overlays & meta | **open** |
| 7 | Full dual QA hard gate + written sign-off | **open — not signed** |
| 8 | Cutover / Steam / OS | **blocked** on Phase 7 |

`function_map.json` / files on disk ≠ dual_ok.  
`npm run port:gates` = structure smoke only.  
`npm run port:dual -- --full` = product gate.

## Live

`USE_GODOT` **off** — client remains **html-legacy** until Phase 7 sign-off.

## Modular structure (do not collapse)

- `WorldDraw.gd` orchestrates one shared `CanvasCompat`
- Full art stays in `scripts/render/drawers/*`
- Systems in `scripts/systems/*`, combat in `scripts/combat/*`
- Performance via shared ctx + caches + tick redraw — never art shortcuts

```bash
npm run port:inventory && npm run port:sync && npm run port:verify
npm run port:dual -- --full
```


## Next: Phase 3 prep

Phase 2 dual leftovers (menu / play / HUD-mini expression matrix, pause chrome, wardrobe menu) are done.

**Phase 3 entry:**
1. `npm run port:gate:3` — weapons/specials/melee/data structure
2. Expand dual for weapon projectiles, specials FX, melee arcs (HTML is truth)
3. Sign rows in `godot/MIGRATION_CHECKLIST.md` Phase 3 only after dual screenshots
4. Still no `USE_GODOT` flip
