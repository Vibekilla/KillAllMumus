# HTML → Godot parity (true 1:1 full port)

## Mandate

Port **`public/index.html` + `public/assets/**`** into Godot **as the same game**.

| Rule | |
| --- | --- |
| Source of truth | HTML + assets only |
| No placeholders | Full drawers for Bobina, mumus, bullets, bosses, menus |
| No “fast” art | No `_draw_fast`, mini-Bobina stand-ins, native-only entity blobs |
| No wrappers | No iframe/WebView of `index.html` for gameplay |
| Same font | **Trebuchet MS** shipped (`godot/assets/fonts/TrebuchetMS*.ttf`) |
| Same assets / SFX | All IMG keys, GIF frame anims, 16 `sfx()` types |
| Same menus + overlays | Canvas states **and** DOM overlays (settings, pause, help, …) |
| Live | HTML until dual QA sign-off (`USE_GODOT` off) |

**File exists ≠ ported.** Real status = **wired into draw path + same behavior + dual QA**.

## Modular Godot structure (keep this)

HTML is one file; Godot stays **modular** for updates and performance:

```
godot/
  autoload/          # Config, GameState, FontBank, ProgressStore, …
  scripts/
    html_parity/     # SimClock, AssetBank, WorldDraw (orchestrator)
    render/
      CanvasCompat.gd
      PortedDraw.gd  # facade over modular drawers
      drawers/       # drawBobina, drawMumu, drawPShot, drawTitle, … (1:1 modules)
    combat/ enemies/ player/ systems/ ui/ audio/
  data/              # JSON tables from HTML constants
  assets/textures + fonts
```

- **WorldDraw** = single presentation pass (HTML `draw()` playfield body), one shared `CanvasCompat`.
- **Entity nodes** = simulation + collision only (`_draw` empty).
- **Drawers** stay separate modules — never collapse into one megascript; never replace a drawer with a circle.
- Performance comes from **structure** (shared ctx, full-circle fill hot path, tick-throttled redraw), not art downgrade.

## Architecture

| Layer | Owner | Role |
| --- | --- | --- |
| World presentation | **WorldDraw** | Full HTML field draw order |
| Menus | Title / FlowUI + drawer modules | Full canvas menu ports |
| HUD panel | HudCanvas | `drawPanel*` only (not stage bg) |
| Overlays | Control UIs | settings, pause, help, soundgate, … |
| Sim | SimClock 60 Hz | HTML `simStep` |

## Phases (full port)

| Phase | Scope | Done when |
| --- | --- | --- |
| P0 | Policy, ban shortcuts, docs | Ban greps clean; docs match this file |
| P1 | WorldDraw single pass | Full drawers wired; dual play not blobs |
| P2 | CanvasCompat + Trebuchet | Dual title/HUD fonts; circle fill fidelity |
| P3 | Title + meta menus | Dual screenshots per menu |
| P4 | DOM overlays in Godot | Every settings/pause/help control |
| P5 | Combat draw + logic | Dual combat + playtest |
| P6 | Stage flow / shop / dialog | Stage 0 clear path |
| P7 | Audio + assets | 16 sfx + all keys + GIF anim |
| P8 | Meta mechanics | Emblems/consumables/NG+ |
| P9 | Dual QA hard gate | Written sign-off below |
| P10 | Cutover / Steam | Only after sign-off |

Structure smoke (`npm run port:gates`) ≠ visual parity. Dual QA is the real product gate.

## Dual QA sign-off

- [ ] Title
- [ ] Play (full Bobina / mumus / bullets)
- [ ] Outfits / arsenal / shop
- [ ] Boss / stage clear / win / game over
- [ ] Settings / pause overlays
- [ ] FPS acceptable on Web without art cuts

```bash
npm run port:inventory
npm run port:gates
npm run port:dual -- --fast   # / --full
```

## Git

Work on **`dev`** (`/var/www/dev`), promote with `./scripts/promote-to-live.sh`.  
Do **not** enable `USE_GODOT=1` until P9 sign-off.
