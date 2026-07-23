# Phase status — HTML → Godot 1:1 port

| Phase | Gate | Status |
| --- | --- | --- |
| P0–P9 | `npm run port:gates` | **ALL PASS** |
| function_map | 290 / 290 | **ported** |
| Live cutover | `USE_GODOT=1` | **not flipped** — remains **html-legacy** |

## What shipped this session

### P8 — progress / emblems / inventory / consumables
- ProgressStore: emblems, estats, heads, consum, shop unlocks, `reset_inventory`, `on_game_cleared` (cabal + speedrun_hell), `compute_emblems`, `content_unlocked` / `lock_cost`
- EmblemSystem full `emblemTick` (score, power, lives, weapons, bride, live best)
- ConsumableSystem: arsenalI cycle, hold 0.8s use, 3s CD, full-check, honeycomb_100
- Inputs: `item_switch` (Q) / `item_use` (E); Settings **R** → reset inventory
- Shop uses lockCost; EndScreen cabal toast; end_run → computeEmblems + saveEstats

### P9 — cloud / residual combat / cutover readiness
- Cloud: `build_progress_snapshot` / `apply_progress_snapshot` / `cloud_linked` / `schedule_cloud_save` / `cloud_pull_and_merge`
- Wynn hell portal sequence on final boss
- Dash land rainbow explosion; clear_wave_mobs; boss mul helpers
- JoyPad touch/virtual stick bridge (remaining P1 DOM helpers)
- Live server still defaults to **html-legacy**

```bash
npm run port:gates
# Gate P0…P9: PASS  ·  residual non-ported: 0
```

## Explicit live cutover (do **not** run until export QA)
1. Export Godot web build into the deploy path (`public_godot/` / export pipeline).
2. Smoke-test with `USE_GODOT=1` on staging only.
3. Promote production env with `USE_GODOT=1` only after sign-off.
