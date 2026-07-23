# Phase status — HTML → Godot true 1:1 port

| Phase | Scope | Status |
| --- | --- | --- |
| P0 | Policy / ban shortcuts / docs | **in progress** — ban greps + docs rewrite |
| P1 | WorldDraw single pass | **in progress** — modular orchestrator + empty entity draws |
| P2 | CanvasCompat + Trebuchet | **in progress** — Trebuchet shipped; circle fill hot path |
| P3–P8 | Menus / combat / flow / audio / meta | structure on disk; dual not signed |
| P9 | Dual QA | **open** |
| P10 | Cutover | **blocked** on P9 |

`function_map.json` entries on disk ≠ dual_ok.  
`npm run port:gates` = structure smoke only.

## Live

`USE_GODOT` **off** — client remains **html-legacy** until sign-off.

## Modular structure (do not collapse)

- `WorldDraw.gd` orchestrates one shared `CanvasCompat`
- Full art stays in `scripts/render/drawers/*`
- Systems in `scripts/systems/*`, combat in `scripts/combat/*`
- Performance via shared ctx + tick redraw + circle fill — never art shortcuts

```bash
npm run port:gates
npm run port:dual -- --fast
```
