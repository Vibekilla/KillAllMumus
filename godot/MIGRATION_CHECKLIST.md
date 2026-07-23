# HTML → Godot full port checklist

Source of truth: `public/index.html` (~5430 lines) + `public/assets/`.  
Structure smoke: `npm run port:gates`. Product gate: dual QA + sign-off in `PARITY.md`.

## Policy

- [x] Modular Godot layout (drawers / systems / WorldDraw orchestrator) — keep forever
- [x] No iframe / HTML shell for gameplay
- [x] Entity `_draw` empty; presentation via WorldDraw
- [x] Trebuchet MS shipped under `godot/assets/fonts/`
- [ ] Dual QA sign-off (title + play + menus)
- [ ] `USE_GODOT=1` only after sign-off

## A. Assets

- [x] Static textures mirrored (`campfire`, clears, portraits, maid, peephole, …)
- [x] GIF frame sequences (`confused`, `talk`, `leekspin`) in AssetBank
- [ ] Every live draw site uses AssetBank (floaters = confused.gif, etc.) — verify dual
- [x] Trebuchet MS + Bold (no silent Noto UI swap)
- [x] Emoji fallback (Noto Color Emoji)

## B. Audio

- [x] SfxSynth WAV bake path
- [ ] All 16 sfx envelopes match HTML
- [ ] Music volume + stream bridge (no game iframe)

## C. Rendering

- [x] CanvasCompat + FontBank
- [x] WorldDraw single-pass (HTML draw order)
- [x] Full-circle `fill()` → native disc (same look, less thrash)
- [x] drawBobina / drawMumu / drawElite / drawPShot / drawBullet / bosses on disk
- [x] Title uses full drawBobina (outfit + maid dance)
- [ ] Pixel dual match title/play/shop
- [ ] Peephole circular clip quality

## D. Data tables

- [x] stages · weapons · specials · melee · outfits · emblems · consumables · ranks/bombs

## E. Combat / systems

- [x] Fire / spawn / melee / bomb / dash / specials (structure)
- [ ] Number parity pass vs HTML (power bleed, graze, extends, boss phases)
- [x] Items / burns / floaters systems
- [x] ProgressStore · emblems · consumables hold-to-use
- [x] StageFlow intro / clear / shop / dialog
- [x] ApiClient absolute web URLs

## F. Menus & overlays

- [x] Canvas title button rows (structure)
- [ ] Dual-perfect outfits / arsenal / emblems / NG+ / leaderboard
- [ ] Godot ports of settings / display / keybinds / help / pause / name entry / shoutouts / soundgate

## G. Cutover

- [ ] Dual playtest sign-off
- [ ] Web export smoke
- [ ] `USE_GODOT=1` after approval
- [ ] Steam desktop export (no `public/` runtime dependency)

## Explicit bans (must stay clean)

- `_draw_fast`, `_draw_mini_bobina`, “Fast path: native” entity art
- Gameplay iframe of `public/index.html`
- Claiming port complete from gate file-presence alone
