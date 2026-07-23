# HTML → Godot full port checklist

Source of truth: `public/index.html` (~5430 lines).  
Gates: `npm run port:gates` (P0–P9 all must PASS).

## Data

- [x] stages (7) + boss metadata  
- [x] weapons (10) · specials (11) · melee (5)  
- [x] outfits · emblems (44) · consumables (11)  
- [x] ranks / bombs / balance / weapon_order  

## Combat

- [x] fire (10 weapons, power 1–5, focus, options)  
- [x] pshot flags · enemy spawn packs · boss phases  
- [x] specials · melee charge · bomb · dash  

## Rendering

- [x] CanvasCompat + FontBank (cached fonts for FPS)  
- [x] WorldCanvas stage bg under entities  
- [x] HudCanvas panel landscape/portrait/touch  
- [x] Title menu 1:1 button rows (no extra HELP wrap row)  
- [x] drawBobina / PShot / bosses / stage bg drawers  
- [ ] Pixel-diff polish vs dual HTML screenshots  
- [ ] Peephole true circular clip quality  

## Systems / meta

- [x] ProgressStore · emblems · consumables hold-to-use  
- [x] StageFlow intro / clear gate / shop / dialog  
- [x] ApiClient absolute web URLs  
- [x] SfxSynth Web-safe WAV  
- [x] 60 FPS cap + tick-throttled redraw  

## Cutover (not done)

- [ ] Dual playtest sign-off (title + play + outfits)  
- [ ] `USE_GODOT=1` only after sign-off  
- [ ] Steam desktop export after web parity  

## Stale notes (removed)

- ~~Feature-branch / ship-feature only commits~~ → direct `dev`/`main`  
- ~~HudCanvas draws stage bg~~ → WorldCanvas only  
- ~~AudioStreamGenerator on web~~ → AudioStreamWAV  
- ~~P7 “HudCanvas wires panel+bg”~~ → panel-only + WorldCanvas  
