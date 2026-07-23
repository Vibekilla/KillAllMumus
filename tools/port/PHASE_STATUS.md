# Phase status — HTML → Godot true 1:1 port

**Canonical plan:** [`godot/PARITY.md`](../../godot/PARITY.md) (phases 0–8).  
**Checkboxes:** [`godot/MIGRATION_CHECKLIST.md`](../../godot/MIGRATION_CHECKLIST.md).

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Foundation / docs / dual as living checklist | **active** — docs + `port:gates` 0–8 |
| 1 | Performance (cache Bobina, throttle redraws) | **in progress** — Bobina cache + StageBg cache + particle batch; GPU/web FPS still open |
| 2 | Bobina animation (breath, blink, expressions, outfits, poses) | **in progress** — wardrobe dual on outfits menu (×4.7); faces/poses/anim/GIF; play-scale dual still open |
| 3 | Exhaustive visuals (weapons / specials / melee / auras / powerups / bosses / meta) | **open** |
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
