# HTML → Godot full port checklist

Source of truth: `public/index.html` (~5430 lines, 298 functions).

## Data (complete)

- [x] stages (7) + boss metadata
- [x] weapons (10)
- [x] specials (11)
- [x] melee (5)
- [x] outfits + colors + emoji
- [x] emblems (44)
- [x] consumables (11)
- [x] ranks / bombs / balance / weapon_order

## Critical combat (ported)

- [x] `fire` — all 10 weapons + power levels 1–5 + focus variants + option familiars
- [x] `optionShot` / `optionOffsets`
- [x] pshot flags: home, laser, wave, nade, petal, zap, vrip, gat, pierce
- [x] `eb` / `ring` / `fanAt` / `heavyShell`
- [x] `spawnWaves` / `spawnLil` / `spawnBig` / `spawnElite`
- [x] enemy AI (lil weave + fire, big/elite hover + rings)
- [x] `updateBoss` all stages 0–6, phases, 45% special, twin swap
- [x] `bossSpecial` by portrait
- [x] `useSpecial` all keys + lasting FX (laser, mech, bearzooka, stampede, badger, sixth, revenge, kiss, kraken, void)
- [x] `doMeleeSwipe` + charged signatures
- [x] `doBomb` / `doDash`

## Rendering

- [x] CanvasCompat (ctx API for 1:1 draw ports)
- [x] PortedDraw.draw_bobina (outfit-tinted Bobina)
- [x] drawPShot weapon shapes on bullets
- [x] boss/enemy procedural sprites
- [x] drawBobina outfit branches ported (visual QA ongoing via dual playtest)
- [ ] drawBobina pixel-diff polish vs HTML screenshots
- [ ] Themed elite sprites (drawElite)
- [ ] Full boss portraits (drawApe/Mumina/Lily/…)
- [x] Stage backgrounds on WorldCanvas under entities (not over them)
- [ ] Boss ambience mandala pixel polish
- [ ] Dialog / portrait GIFs / maid dance

## Meta / UI

- [x] GameState flow, ProgressStore cloud, ApiClient
- [x] Title / HUD / Pause / Display / Settings
- [x] Shop / Arsenal / Emblems / Outfits / NG / Leaderboard shells
- [ ] Shop canvas layout 1:1
- [ ] Touch joystick full parity
- [ ] SFX synth parity

## Verify

```bash
node tools/port/verify_parity.mjs   # critical gate
godot --headless --path godot --export-release Web ../public_godot/index.html
```

Live: `USE_GODOT=1` (default) serves `public_godot/`. Rollback: `USE_GODOT=0`.

## Steam

- [ ] Desktop export after web parity
- [ ] Remove dual-client HTML only after cutover sign-off
