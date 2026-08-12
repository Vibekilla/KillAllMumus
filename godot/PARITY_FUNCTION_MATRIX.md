# HTML → Godot full function matrix (dev)

Generated for final 1:1 port pass. Source: `public/index.html` function declarations.

**Rule:** HTML is truth. No approximations.  
**This matrix = coverage / structure only.**  
`ported` here means “has a Godot home + phase unit/structure evidence,” **not** product dual eye-pass.

| Doc | Use for |
| --- | --- |
| This file | Function map + matrix phase COMPLETE (structure) |
| [`tools/port/PHASE_STATUS.md`](../tools/port/PHASE_STATUS.md) | Structure vs product rollup |
| [`PARITY_RESIDUALS.md`](./PARITY_RESIDUALS.md) / [`DUAL_PRODUCT_FAIL_LIST.md`](./DUAL_PRODUCT_FAIL_LIST.md) | Product gaps |

**Rule for advancing product:** dual still + eye-pass → fail list / residuals, then PHASE_STATUS product column.

## Counts

| Status | Count | Meaning |
| --- | ---: | --- |
| ported | 290 | Structure mapped (not product_ok) |
| unmapped | 9 | Platform wrappers (intentional) |
| **Total** | **299** | |

## Method

1. Pick next `unmapped` / open residual by phase (1→7)
2. Open HTML function body → locate Godot
3. Diff line-by-line (numbers, order, early-returns)
4. Fix Godot (or document intentional HTML bug fixed in Godot)
5. Unit test if numeric; dual still if visual
6. `npm run export:godot` → verify on https://dev.killallmumus.com/
7. Update this matrix status

## Phase 1 priority (perf + Bobina draw path)

- [x] `drawBobina` — ported → `godot/scripts/render/drawers/drawBobina.gd`
- [x] `drawStageBg` — ported → `godot/scripts/ui/menu/draw_hud.gd`
- [x] `drawStageBgFx` — ported → `godot/scripts/ui/menu/draw_hud.gd`
- [x] `drawPowerAura` — ported → `godot/scripts/render/drawers/drawCombatFx.gd`
- [x] `drawPowerRadiance` — ported → `godot/scripts/render/drawers/drawCombatFx.gd`
- [x] `drawDashComet` — ported → `godot/scripts/render/drawers/drawCombatFx.gd`
- [x] `drawOptions` — ported → `godot/scripts/render/drawers/drawCombatFx.gd`
- [x] `bodyCtr` — ported → `godot/scripts/combat/CombatHelpers.gd`
- [x] `optionPos` — ported → `godot/scripts/combat/FireSystem.gd`
- [x] `optionOffsets` — ported → `godot/scripts/combat/FireSystem.gd`
- [x] `pOrb` — ported → `godot/scripts/render/drawers/drawBobina.gd`
- [x] `applyLayout` — ported → `godot/autoload/Config.gd`
- [x] `update` — ported → `godot/scripts/main/Main.gd`



## Phase 1 residual notes (2026-08-12 final pass)

| Item | HTML truth | Godot fix |
| --- | --- | --- |
| Feet platform | drawBobina shadow at local (0,20) after rot about feet | Face-bin bake feet at tex center; blit `px-tw/2, py-th/2` |
| Soap bubble center | `bodyCtr` = orbit of body about (x,y-16) | Aura/options/shield/rapid/vial/phase all use `body_ctr`; visual face shared with face bins (24) |
| lean | play always 0 | removed invented velocity lean |
| FPS | canvas 2d cheap | face-bin cache (live only dash/bomb); stage bg bake; play stride 30 Hz |
| drawDashComet | radial tail + rim=18 head + sparkles | full gradients + particles while dashing |
| drawPowerAura sparks | LV5 every 3 ticks + pf trail | spawn into CombatHelpers.particles |
| Field victory pose | drawPosedFigure motionScale 0 after boss dead | `_draw_posed_field` + sway/bounce*0.4 + aura follow |
| stageTime scroll | `stageTime\|\|tick` motif | drawStageBg uses EnemySpawner.stage_time |
| particle gravity | `q.vy+=0.12` | `CombatHelpers.tick_fx` |
| optionPos | aim/face + (oy+16) body pivot | FireSystem prefers player.aim |

Unmapped (9): applyMe, bumpIdle, hookCloudSaves, loadMe, loginHref, paint, run, syncAccount, wrap — platform/account wrappers, not combat sim.



## Phase 1 `update()` map (HTML → Godot)

HTML `update()` (public/index.html ~2405) is distributed across SimClock subscribers @ 60 Hz:

| HTML section | Godot |
| --- | --- |
| `tick++` | `SimClock._step` → `sim_frame` |
| `flashMsg.t--` | `CombatHelpers.tick_fx` / `_tick_flash` (before death freeze) |
| intro / win / !play / paused early-outs | `GameState.state` gates on each subscriber |
| `p.dead` → respawn + `updateItems` only | `Player._step` death branch; `ItemSystem.tick` items-only when `player_down` |
| timers iframe/bomb/shield/rapid/dashCd/vial/phase | `Player._step` |
| `offx/offy*=0.95`, focus, moveT | `Player` + `JoyPad` |
| movement / dash 18 / knock / face hold | `Player._step` |
| power −0.00085, special +0.012 | `GameState._on_sim_tick` |
| fire / melee / flurry | `FireSystem` + `MeleeSystem` + `Player` |
| waves / stageTime | `EnemySpawner` |
| pshots / bullets / graze | `BulletPool` + `Bullet` |
| slowmo 0.4/0.5/0.75 | `CombatHelpers.tick_slowmo` |
| enemies / burns / boss | `EnemyBase` + `ItemSystem` + `BossController` |
| items / floaters / emotes | `ItemSystem.tick` |
| particles `vy+=0.12` + score pops | `CombatHelpers.tick_fx` |
| `updateFx` specials | `SpecialSystem` |

**Intentional HTML fixes in Godot:** mouse drag requires recent `moveT` (not bare LMB) to avoid click-to-fire corner yank.



## Phase 2 checklist (menus / arsenal / run init)

- [x] `newRun` / `startRun` / `initPlayer` — lives 6, bombs 3, power 1, special 15, iframe 120, y=PF.h-70
- [x] `toggleArsenal` / `moveArsenal` / `dropToSlot` / `unequipArsenal` / `saveArsenal` — ARS_CAP w5 s5 m2 i3
- [x] `arsArr` / `arsPool` / `arsItemByKey` / `armedSpec` / `applyArsenalToRun`
- [x] `addWeapon` / `addSpecial` / `addMelee` / `addBomb` — DataRegistry extend
- [x] `applyDiff` / `modeTag` / `diffName` / `outfitColors`
- [x] `drawArsenal` / `drawTitle` / `drawTitleBtn` / `drawMenuBtn`
- [x] `drawOutfits` / `drawEmblems` / `drawNgSelect` / `drawLeaderboard`
- [x] `submitScore` / `fetchLB` / `lbIsMine` / `tweetResult`
- [x] `handleTitleClick` / `exitArsenal` / `fmtScore` / `emPageCount`

**Phase 2 residuals fixed 2026-08-12:** empty weapons → laser (HTML starter); dropToSlot sfx; unequip clamps selConsum; P2Meta.drop_to_slot.



## Phase 2 sign-off (2026-08-12)

**Status: COMPLETE** — all 36 matrix functions present and behavioral checks green.

| Evidence | Result |
| --- | --- |
| Name coverage (36/36) | PASS |
| Structural constants (53 checks) | PASS |
| Runtime arsenal/mode/fmtScore (`test_phase2_runtime.gd`) | PASS |
| Static guards (`test_phase2_parity.gd`) | PASS |

Fixes in Phase 2 closeout:
- empty weapons → laser (HTML starter)
- dropToSlot sfx + P2Meta API
- unequip clamps selConsum
- exitArsenal always sfx('item') + clear arsDrag



## Phase 3 checklist (render helpers / Bobina FX)

- [x] `lerpAngle` — CombatHelpers.lerp_angle
- [x] `circle` / `limb` / `pOrb` — drawer modules
- [x] `coffeeHold` / `poseParams` / `drawPoseProp` — drawCombatFx 1:1
- [x] `drawMeleeWeapon` — katana/lash/scythe/hammer/claws full HTML
- [x] `drawPowerAura` / `drawPowerRadiance` / `drawDashComet` / `drawOptions` (shared Phase 1)
- [x] `drawBobina` — live+cache hybrid (Phase 1)
- [x] `drawOutfitFigure` / posed figure — draw_menus + field victory

## Phase 3 sign-off (2026-08-12)

**Status: COMPLETE** — 14/14 functions.

| Evidence | Result |
| --- | --- |
| test_phase3_parity (poseParams, coffeeHold, lerpAngle, melee keys) | PASS |
| drawMeleeWeapon HTML lash N=18 + katana ellipse tsuba | fixed |
| drawPoseProp steam sip&lt;0.5 + gradient flame | fixed |
| charge ring body_ctr face-aware | fixed |



## Phase 4 checklist (combat helpers / bomb / hit / fire)

- [x] `powerCap` / `powerGainMul` / `shotLevel` / `addPower` / `gainLife`
- [x] `scoreMult` / `threatMul` / `rankIndex` / `rankLetter` / `diffScoreMul`
- [x] `burst` / `sparks` / `pop` / `aimAngle` / `angDiff` / `lineTime` / `nearestTarget`
- [x] `swapWeapon` / `cycleSpecial`
- [x] `fire` / `optionOffsets` / `optionPos` / `optionShot`
- [x] `doBomb` / `doDash` / `hitPlayer`
- [x] `update` (Phase 1 map)

## Phase 4 sign-off (2026-08-12)

**Status: COMPLETE** — 25/25 functions.

| Evidence | Result |
| --- | --- |
| test_phase4_parity | PASS |
| nearestTarget skips dead/intro boss | fixed |
| addPower no extra sfx (HTML) | fixed |
| optionShot scatter/lotus offsets | HTML formula |



## Phase 5 checklist (items / kills / spawn / specials / draw)

- [x] `killEnemy` / `dropLoot` / `dropItem` / `dropWeapon` / `collectItem`
- [x] `checkExtend` / `killExtend` / `eliteHearts` / EXTEND_SCORES / KILL_EXTEND
- [x] `chainLightning` / `nadeBoom` / `enemyExplode`
- [x] `spawnLil` / `spawnBig` / `spawnElite` / `spawnWaves` / ELITE_* tables
- [x] `eb` / `ring` / `fanAt` / `heavyShell` (SPD)
- [x] `spawnBubbles` / `spawnStardust` / `updateItems` / `updateBurns` / `updateFx`
- [x] `useSpecial` / `specialButton` / `emote`
- [x] `drawMumu` / `drawElite` / `drawItem` / `drawFx` / `drawMech` / `drawBobo` / `drawFloater` / `drawBurns` / `drawEmote`

## Phase 5 sign-off (2026-08-12)

**Status: COMPLETE** — 36/36 functions.

| Evidence | Result |
| --- | --- |
| test_phase5_parity | PASS |
| Name coverage 36/36 | PASS |
| enemyExplode screenShake 3.5 | fixed |



## Phase 6 checklist (stages / boss / clear / win)

- [x] `loadStage` / `spawnBoss` / `updateBoss` / `bossSpecial` / `twinSwap`
- [x] `onBossDefeated` / `enterPortal` / `enterShop` / `leaveShop` / `advanceScreen`
- [x] `startDialog` / intro timers 140/120/20 speedrun
- [x] `drawIntro` / `drawStageClear` / `drawClearGate`
- [x] `drawBoss` + portrait drawers (ape/mumina/wynn/devil/lily/police/bogdanoff/robotnik)
- [x] `drawWin` / `drawGameOver` / `onGameCleared` emblems

## Phase 6 sign-off (2026-08-12)

**Status: COMPLETE** — 23/23 functions.

| Evidence | Result |
| --- | --- |
| test_phase6_parity | PASS |
| Name coverage 23/23 | PASS |
| boss HP ×(2.1+stage×0.07), r38, twin 60%, deadT>150 | verified |


## Phase 7 checklist (UI / render helpers / modals)

- [x] `_hEsc` / `wrapText` / `anyModalOpen` — MenuHelpers (+ InputRouter gate)
- [x] `_hItem` / `_hSec` / `buildHelp` / `openHelp` / `closeHelp` — HelpData + HelpCanvas
- [x] `_hexA` / `_hexRgb` / `drawHeart` — draw_hud + EndScreen bezier `#ff4d8d`
- [x] `draw` order / stun stars / charm — WorldDraw + PortedDraw drawers
- [x] `drawStageBg` / `drawStageBgFx` / `drawBossAmbience` (radial vignette + mandala)
- [x] `drawPhaseVeil` (lanes + shear 162/26) / `drawSlowmoFx` / `drawHellPortal`
- [x] `drawPanel` / portrait / touch / `drawEmblemToasts` / `drawPause` → PauseMenu card
- [x] `drawDialog` / `drawShop` / `shopList` / `shopBuySelected` / `bobinaSay`
- [x] `drawBullet` / `drawPShot` / `drawMeleeFx` / bosses (Bogdanoff/Robotnik) / HoneyBadger
- [x] `drawMaidDance` / `drawPosedFigure` / `drawPortraitBust` / `manageGifOverlays` (AssetBank)
- [x] `neutralizeInputs` / pause-settings-display-keybinds open/close/sync
- [x] `drawShareBtn` / `drawDebugLayer` / `overlayShow` (DOM→canvas GIF path)

## Phase 7 sign-off (2026-08-12)

**Status: COMPLETE (matrix / structure only)** — 62/62 matrix functions (UI/render/modals).

| Evidence | Result |
| --- | --- |
| test_phase7_parity | PASS |
| test_phase5/6 + neutralize + help_shoutouts | PASS |
| port:gate:7 (dual harness structure) | PASS |
| Fixes this pass | phase veil 1:1, heart bezier, boss vignette, anyModalOpen |

> **matrix COMPLETE ≠ product complete.** Product Phase 7 remains **hold** (CUTOVER HOLD).  
> See `PHASE_STATUS.md`. `USE_GODOT` stays off until PARITY.md **product** sign-off.


## Full matrix

| Function | Phase | Status | Godot |
| --- | --- | --- | --- |
| `_hEsc` | 7 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` (`h_esc`) |
| `_hItem` | 7 | ported | `godot/scripts/ui/menu/HelpData.gd` |
| `_hSec` | 7 | ported | `godot/scripts/ui/menu/HelpData.gd` |
| `_hexA` | 7 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `_hexRgb` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `_rgbHue` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `actx` | 1 | ported | `godot/scripts/audio/SfxSynth.gd` |
| `addBomb` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `addMelee` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `addPower` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `addSpecial` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `addWeapon` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `advanceScreen` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `aimAngle` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `angDiff` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `anyModalOpen` | 7 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` (+ InputRouter) |
| `applyArsenalToRun` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `applyDiff` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `applyLayout` | 1 | ported | `godot/autoload/Config.gd` |
| `applyMe` |  | unmapped |  |
| `applyMusicVol` | 9 | ported | `godot/autoload/AudioBus.gd` |
| `applyProgressSnapshot` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `applySfxVol` | 9 | ported | `godot/autoload/AudioBus.gd` |
| `armedSpec` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `arsArr` | 2 | ported | `godot/scripts/ui/menu/MenuModel.gd` |
| `arsItemByKey` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `arsPool` | 2 | ported | `godot/scripts/ui/menu/MenuModel.gd` |
| `arsenalCount` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `bobinaSay` | 7 | ported | `godot/scripts/stages/StageFlow.gd` |
| `bodyCtr` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `bossDmgMul` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `bossSpecial` | 6 | ported | `godot/scripts/enemies/bosses/BossController.gd` |
| `bossWepMul` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `buildHelp` | 7 | ported | `godot/scripts/ui/menu/HelpData.gd` |
| `buildProgressSnapshot` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `bulletCancelAll` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `bulletCancelNear` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `bumpIdle` |  | unmapped |  |
| `burst` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `cabalUnlocked` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `canvasPos` | 1 | ported | `godot/scripts/player/Player.gd` |
| `chainLightning` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `checkExtend` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `circle` | 3 | ported | `godot/scripts/render/drawers/drawBobina.gd` |
| `clearWaveMobs` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `closeDisplay` | 7 | ported | `godot/scripts/ui/DisplayMenu.gd` |
| `closeGate` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `closeHelp` | 7 | ported | `godot/scripts/ui/HelpCanvas.gd` |
| `closeKeybinds` | 7 | ported | `godot/scripts/ui/KeybindsMenu.gd` |
| `closeSettings` | 7 | ported | `godot/scripts/ui/SettingsMenu.gd` |
| `closeShoutouts` | 7 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `cloudLinked` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `cloudPullAndMerge` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `coffeeHold` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `collectItem` | 5 | ported | `godot/scripts/enemies/EnemyBase.gd` |
| `computeEmblems` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `consumById` | 9 | ported | `godot/scripts/systems/ConsumableSystem.gd` |
| `consumQty` | 9 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` |
| `consumeSelected` | 8 | ported | `godot/scripts/systems/ConsumableSystem.gd` |
| `contentUnlocked` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `controlsHtml` | 7 | ported | `godot/scripts/ui/SettingsMenu.gd` / HelpData |
| `cycleConsumable` | 8 | ported | `godot/scripts/systems/ConsumableSystem.gd` |
| `cycleSpecial` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `dashLandExplosion` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `diffName` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `diffScoreMul` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `doBomb` | 4 | ported | `godot/scripts/player/Player.gd` |
| `doDash` | 4 | ported | `godot/scripts/player/Player.gd` |
| `doMeleeSwipe` | 9 | ported | `godot/scripts/systems/MeleeSystem.gd` |
| `doSaveScore` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `draw` | 7 | ported | `godot/scripts/html_parity/WorldDraw.gd` (+ PortedDraw) |
| `drawApe` | 6 | ported | `godot/scripts/render/drawers/drawApe.gd` |
| `drawArsenal` | 2 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawBobina` | 3 | ported | `godot/scripts/render/drawers/drawBobina.gd` |
| `drawBobo` | 5 | ported | `godot/scripts/render/drawers/drawBobo.gd` |
| `drawBogdanoff` | 7 | ported | `godot/scripts/render/drawers/drawBogdanoff.gd` |
| `drawBoss` | 6 | ported | `godot/scripts/render/drawers/drawBoss.gd` |
| `drawBossAmbience` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawBullet` | 7 | ported | `godot/scripts/render/drawers/drawBullet.gd` |
| `drawBurns` | 5 | ported | `godot/scripts/render/FxLayer.gd` |
| `drawClearGate` | 6 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `drawDashComet` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawDebugLayer` | 7 | ported | `godot/scripts/ui/menu/draw_debug.gd` |
| `drawDevil` | 6 | ported | `godot/scripts/render/drawers/drawDevil.gd` |
| `drawDialog` | 7 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `drawElite` | 5 | ported | `godot/scripts/render/drawers/drawElite.gd` |
| `drawEmblemToasts` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawEmblems` | 2 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawEmote` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `drawFloater` | 5 | ported | `godot/scripts/render/FxLayer.gd` |
| `drawFx` | 5 | ported | `godot/scripts/render/drawers/drawFx.gd` |
| `drawGameOver` | 6 | ported | `godot/scripts/ui/EndScreen.gd` |
| `drawHeart` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` + EndScreen |
| `drawHellPortal` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawHoneyBadger` | 7 | ported | `godot/scripts/render/drawers/drawHoneyBadger.gd` |
| `drawIntro` | 6 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `drawItem` | 5 | ported | `godot/scripts/render/drawers/drawItem.gd` |
| `drawLeaderboard` | 2 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawLily` | 6 | ported | `godot/scripts/render/drawers/drawLily.gd` |
| `drawMaidDance` | 7 | ported | `godot/scripts/render/drawers/drawTitle.gd` |
| `drawMech` | 5 | ported | `godot/scripts/render/drawers/drawMech.gd` |
| `drawMeleeFx` | 7 | ported | `godot/scripts/render/drawers/drawMeleeFx.gd` |
| `drawMeleeWeapon` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawMenuBtn` | 2 | ported | `godot/scripts/render/drawers/drawTitle.gd` |
| `drawMumina` | 6 | ported | `godot/scripts/render/drawers/drawMumina.gd` |
| `drawMumu` | 5 | ported | `godot/scripts/render/drawers/drawMumu.gd` |
| `drawNgSelect` | 2 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawOptions` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawOutfitFigure` | 3 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawOutfits` | 2 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawPShot` | 7 | ported | `godot/scripts/render/drawers/drawPShot.gd` |
| `drawPanel` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawPanelPortrait` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawPanelTouch` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawPause` | 7 | ported | `godot/scripts/ui/PauseMenu.gd` (HTML #pausescreen) |
| `drawPhaseVeil` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawPolice` | 6 | ported | `godot/scripts/render/drawers/drawPolice.gd` |
| `drawPortraitBust` | 7 | ported | `godot/scripts/render/drawers/drawPortraitBust.gd` |
| `drawPoseProp` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawPosedFigure` | 7 | ported | `godot/scripts/ui/menu/draw_menus.gd` |
| `drawPowerAura` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawPowerRadiance` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `drawRobotnik` | 7 | ported | `godot/scripts/render/drawers/drawRobotnik.gd` |
| `drawShareBtn` | 7 | ported | `godot/scripts/ui/EndScreen.gd` |
| `drawShop` | 7 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `drawSlowmoFx` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawStageBg` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawStageBgFx` | 7 | ported | `godot/scripts/ui/menu/draw_hud.gd` |
| `drawStageClear` | 6 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `drawStunStars` | 7 | ported | `godot/scripts/html_parity/WorldDraw.gd` |
| `drawTitle` | 2 | ported | `godot/scripts/render/drawers/drawTitle.gd` |
| `drawTitleBtn` | 2 | ported | `godot/scripts/render/drawers/drawTitle.gd` |
| `drawWin` | 6 | ported | `godot/scripts/ui/EndScreen.gd` |
| `drawWynn` | 6 | ported | `godot/scripts/render/drawers/drawWynn.gd` |
| `dropItem` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `dropLoot` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `dropToSlot` | 2 | ported | `godot/scripts/ui/menu/MenuModel.gd` |
| `dropWeapon` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `eb` | 5 | ported | `godot/scripts/combat/BulletPatterns.gd` |
| `eliteHearts` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `emPageCount` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `emblemCount` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `emblemDef` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `emblemTick` | 8 | ported | `godot/scripts/systems/EmblemSystem.gd` |
| `emote` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `enemyExplode` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `enterPortal` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `enterShop` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `exitArsenal` | 2 | ported | `godot/scripts/ui/TitleScreen.gd` |
| `fanAt` | 5 | ported | `godot/scripts/combat/BulletPatterns.gd` |
| `fetchLB` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `fire` | 4 | ported | `godot/scripts/combat/FireSystem.gd` |
| `fit` | 1 | ported | `godot/autoload/Config.gd` |
| `fmtScore` | 2 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` |
| `gainLife` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `goFullscreenMobile` | 9 | ported | `godot/autoload/Config.gd` |
| `handleTitleClick` | 2 | ported | `godot/scripts/ui/TitleScreen.gd` |
| `hasEmblem` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `heavyShell` | 5 | ported | `godot/scripts/combat/BulletPatterns.gd` |
| `hideNameEntry` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `hitPlayer` | 4 | ported | `godot/scripts/player/Player.gd` |
| `hookCloudSaves` |  | unmapped |  |
| `imgOK` | 1 | ported | `godot/scripts/html_parity/AssetBank.gd` |
| `inBtn` | 1 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` |
| `initMaster` | 1 | ported | `godot/scripts/audio/SfxSynth.gd` |
| `initPlayer` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `joyApply` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `joyEnd` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `joyHomePos` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `joyMove` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `joyReset` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `joyShowHome` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `joyStart` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `kb` | 1 | ported | `godot/project.godot` |
| `keyName` | 1 | ported | `godot/project.godot` |
| `keyPress` | 1 | ported | `godot/scripts/input/InputRouter.gd` |
| `killEnemy` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `killExtend` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `lbIsMine` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `lbPageCount` | 9 | ported | `godot/scripts/ui/menu/MenuModel.gd` |
| `lbSetPage` | 9 | ported | `godot/scripts/ui/menu/MenuModel.gd` |
| `leaveShop` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `lerpAngle` | 3 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `limb` | 3 | ported | `godot/scripts/render/drawers/drawBobina.gd` |
| `lineTime` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `load` | 1 | ported | `godot/scripts/html_parity/AssetBank.gd` |
| `loadMe` |  | unmapped |  |
| `loadStage` | 6 | ported | `godot/scripts/stages/StageController.gd` |
| `lockCost` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `loginHref` |  | unmapped |  |
| `loop` | 1 | ported | `godot/scripts/html_parity/SimClock.gd` |
| `manageGifOverlays` | 7 | ported | AssetBank + draw_flow talk gif |
| `manageTouchUI` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `measureLines` | 7 | ported | `godot/scripts/ui/menu/draw_flow.gd` (`_wrap_dialog_lines`) |
| `meleeChargeFx` | 9 | ported | `godot/scripts/systems/MeleeSystem.gd` |
| `meleeIdxList` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `modeTag` | 2 | ported | `godot/autoload/GameState.gd` |
| `moveArsenal` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `musicPause` | 9 | ported | `godot/autoload/AudioBus.gd` |
| `musicPlay` | 9 | ported | `godot/autoload/AudioBus.gd` |
| `nadeBoom` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `nearestTarget` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `neutralizeInputs` | 7 | ported | `godot/scripts/stages/StageFlow.gd` |
| `newRun` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `onBossDefeated` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `onFsChange` | 1 | ported | `godot/autoload/Config.gd` |
| `onGameCleared` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `openDisplay` | 7 | ported | `godot/scripts/ui/DisplayMenu.gd` |
| `openHelp` | 7 | ported | `godot/scripts/ui/HelpCanvas.gd` |
| `openKeybinds` | 7 | ported | `godot/scripts/ui/KeybindsMenu.gd` |
| `openSettings` | 7 | ported | `godot/scripts/ui/SettingsMenu.gd` / TitleScreen |
| `openShoutouts` | 7 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `optionOffsets` | 4 | ported | `godot/scripts/combat/FireSystem.gd` |
| `optionPos` | 4 | ported | `godot/scripts/combat/FireSystem.gd` |
| `optionShot` | 4 | ported | `godot/scripts/combat/FireSystem.gd` |
| `outfitColors` | 2 | ported | `godot/autoload/DataRegistry.gd` |
| `outfitUnlocked` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `overlayHide` | 7 | ported | canvas GIF path (AssetBank; no DOM) |
| `overlayShow` | 7 | ported | canvas GIF path (AssetBank; no DOM) |
| `pOrb` | 3 | ported | `godot/scripts/render/drawers/drawBobina.gd` |
| `paint` |  | unmapped |  |
| `pauseReturnMenu` | 7 | ported | `godot/scripts/ui/PauseMenu.gd` |
| `pdown` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `pmove` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `pop` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `poseParams` | 3 | ported | `godot/scripts/render/drawers/drawCombatFx.gd` |
| `powerCap` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `powerGainMul` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `pup` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `rankIndex` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `rankLetter` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `readUiOverride` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `rebuildKMAP` | 1 | ported | `godot/project.godot` |
| `renderKeybinds` | 7 | ported | `godot/scripts/ui/KeybindsMenu.gd` |
| `resetInventory` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `resumeGame` | 7 | ported | `godot/scripts/ui/PauseMenu.gd` |
| `ring` | 5 | ported | `godot/scripts/combat/BulletPatterns.gd` |
| `run` |  | unmapped |  |
| `saveArsenal` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `saveBinds` | 1 | ported | `godot/project.godot` |
| `saveConsum` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `saveDisplayPrefs` | 1 | ported | `godot/autoload/Config.gd` |
| `saveEmblems` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `saveEstats` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `saveHeads` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `saveNgPrefs` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `saveShopUnlocks` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `scheduleCloudSave` | 9 | ported | `godot/autoload/ProgressStore.gd` |
| `scoreMult` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `selConsumObj` | 9 | ported | `godot/scripts/systems/ConsumableSystem.gd` |
| `setBind` | 1 | ported | `godot/project.godot` |
| `setDebugLayer` | 1 | ported | `godot/autoload/Config.gd` |
| `setDisplayScale` | 1 | ported | `godot/autoload/Config.gd` |
| `setRefreshRate` | 1 | ported | `godot/autoload/Config.gd` |
| `sfx` | 1 | ported | `godot/scripts/audio/SfxSynth.gd` |
| `shopBuySelected` | 7 | ported | `godot/scripts/ui/FlowUI.gd` |
| `shopList` | 7 | ported | `godot/scripts/ui/menu/draw_flow.gd` |
| `shotLevel` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `shotLevelCap` | 9 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `showNameEntry` | 9 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `simStep` | 1 | ported | `godot/scripts/html_parity/SimClock.gd` |
| `sparks` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `spawnBig` | 5 | ported | `godot/scripts/enemies/EnemySpawner.gd` |
| `spawnBoss` | 6 | ported | `godot/scripts/stages/StageController.gd` |
| `spawnBubbles` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `spawnClearGate` | 9 | ported | `godot/scripts/stages/StageFlow.gd` |
| `spawnElite` | 5 | ported | `godot/scripts/enemies/EnemySpawner.gd` |
| `spawnLil` | 5 | ported | `godot/scripts/enemies/EnemySpawner.gd` |
| `spawnStardust` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `spawnWaves` | 5 | ported | `godot/scripts/enemies/EnemySpawner.gd` |
| `specialButton` | 5 | ported | `godot/scripts/systems/SpecialSystem.gd` |
| `startDialog` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `startRun` | 2 | ported | `godot/autoload/GameState.gd` |
| `startWynnHell` | 9 | ported | `godot/scripts/enemies/bosses/BossController.gd` |
| `submitScore` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `swapWeapon` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `syncAccount` |  | unmapped |  |
| `syncDisplayUI` | 7 | ported | `godot/scripts/ui/DisplayMenu.gd` |
| `syncPauseUI` | 7 | ported | `godot/scripts/ui/PauseMenu.gd` |
| `syncSettingsUI` | 7 | ported | `godot/scripts/ui/SettingsMenu.gd` |
| `threatMul` | 4 | ported | `godot/scripts/combat/CombatHelpers.gd` |
| `toggleArsenal` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `toggleFullscreen` | 1 | ported | `godot/autoload/Config.gd` |
| `tweetResult` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `twinSwap` | 6 | ported | `godot/scripts/stages/StageFlow.gd` |
| `unequipArsenal` | 2 | ported | `godot/scripts/ui/menu/P2Meta.gd` |
| `unlockEmblem` | 8 | ported | `godot/autoload/ProgressStore.gd` |
| `update` | 4 | ported | `godot/scripts/main/Main.gd` |
| `updateBoss` | 6 | ported | `godot/scripts/enemies/bosses/BossController.gd` |
| `updateBurns` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `updateFx` | 5 | ported | `godot/scripts/systems/SpecialSystem.gd` |
| `updateItems` | 5 | ported | `godot/scripts/systems/ItemSystem.gd` |
| `updatePortrait` | 7 | ported | HTML no-op → dialog talk gif in draw_flow |
| `updateTouchButtons` | 1 | ported | `godot/scripts/input/JoyPad.gd` |
| `updateWynnHell` | 9 | ported | `godot/scripts/enemies/bosses/BossController.gd` |
| `useSpecial` | 5 | ported | `godot/scripts/systems/SpecialSystem.gd` |
| `wrap` |  | unmapped |  |
| `wrapLines` | 7 | ported | `godot/scripts/ui/menu/draw_flow.gd` (`_wrap_dialog_lines`) |
| `wrapText` | 7 | ported | `godot/scripts/ui/menu/MenuHelpers.gd` |
