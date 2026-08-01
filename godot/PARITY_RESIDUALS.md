# HTML → Godot residual gaps (living audit)

Source of truth: `public/index.html` + `public/assets/`.  
Structure duals/gates can be green while **product** still differs. This file lists known residuals so we do not mark Phase 7 complete early.

**Policy:** live stays `html-legacy` until Phase 7 sign-off. Work on **dev** (`USE_GODOT=1`). Export always: `npm run export:godot` → `/var/www/dev/public_godot`.

---

## Method (going forward)

```bash
cd /var/www/dev
# Always export so BOTH previews get the same public_godot:
npm run export:godot
# → /var/www/dev/public_godot
# → rsync mirror /var/www/killallmumus.com/public_godot
# Test:
#   https://dev.killallmumus.com/          (USE_GODOT=1 default on dev)
#   https://dev.killallmumus.com/godot/
#   https://killallmumus.com/godot/        (preview only; / stays html-legacy)
# Commit + promote still required for git main / server.js / non-godot assets.
```

HTML function → Godot port → **behavior** diff → dual/test → export **both** worktrees → only then check off.

---

## P0 — User-facing blockers (reported / confirmed)

| Area | HTML truth | Godot residual | Status |
|------|------------|----------------|--------|
| **Soundgate → music** | Every load shows gate; **Play** → `initMaster()` + `musicPlay()` (YT lofi) | (1) permanent `soundgate_seen` skipped gate (2) **`COEP: require-corp` on /godot/** blocked youtube.com iframe even with threads off | **Fixed**: session gate + no COEP unless threads; MusicBridge retries |
| **Soundgate → fullscreen** | `goFullscreenMobile()` **touch only** | Was always fullscreen | **Fixed** (touch/web only) |
| **Soundgate look** | CSS `.sg-card`, campfire 16:9, pink pulse CTA | Canvas approx. | Improved; landscape grid still residual |
| **Title under gate** | Opaque DOM over canvas | Canvas gate z=80 | Verify dim full viewport after hard-refresh |
| **Export visibility** | N/A | Dev-only export left live `/godot/` stale | **Fixed**: `export:godot` mirrors live `public_godot` |

---

## P1 — UI / meta (structure duals exist; product still open)

| Area | Residual |
|------|----------|
| **Title** | Peephole, social strip, micro-copy, button layout vs DOM/canvas mix |
| **Outfits menu** | Spotlight / clip / continuous anim timing polish at ×4.7 |
| **Arsenal / Emblems / LB** | Chrome density, empty states, cloud merge UX |
| **Settings** | Mostly dualed; speedrun/reset copy polish |
| **Display** | OverlayTheme card + presets done; not full HTML section hints |
| **Keybinds** | List works; rebind UX / gamepad glyph polish |
| **Pause** | Godot has full buttons; HTML dual often crops; blur vs solid dim |
| **Help / Shoutouts** | Structure duals; scroll/tab content polish |
| **Name entry** | Dual still; input focus + save path product pass |
| **Touch chrome** | Dual still (stick + rail); hit targets / safe-area / cycle button parity |
| **Music volume in settings** | Must drive YT via MusicBridge (wired); web mute product pass open |

---

## P2 — Flow / dialog / stage

| Area | Residual |
|------|----------|
| **Intro** | Dual structure; stage text / “PRESS Z” timing |
| **Boss intro dialog** | FlowUI fixed dismiss clear; line timing, talk GIF, skip vs speedrun |
| **Boss taunts / phase dialog** | Special taunt lines; twin swap dialogue |
| **Shop (Honey Badger)** | Dual close; quote RNG, buy feedback, tab focus, leave → clear |
| **Stage clear** | Dual close; leekspin GIF product, rank formula display |
| **Clear portal / gate** | Timing test green; visual portal product |
| **Win / Game over** | Dual close; NG+ banner, emblem list, share |
| **Leekspin / maid dance** | Easter eggs product pass open |
| **Dialog functions** | `bobinaSay`, hurt lines, emblem toasts mid-dialog stacking |

---

## P3 — Combat visuals (structure duals largely green)

| Area | Residual |
|------|----------|
| **Weapons** | Shapes 1:1 structure; density/timing vs HTML dual stills; product sign-off open |
| **Specials** | Laser beam, mech escort, sixth slowmo FX structure; product polish open |
| **Melee** | Swipe arcs dualed; charge FX / dash-slash product |
| **Auras** | Power/soap bubble dualed; high-power color product |
| **Boss art** | Portrait duals; minions (e.g. Robotnik badniks), ambience mandala, hell portal product |
| **Elites / mumus / items** | Grids dualed; stage bg motif intensity; item emoji glyph font |
| **Particles / floaters** | Score pops, burns, charm hearts product density |

---

## P4 — Mechanics (unit tests green ≠ full matrix)

| Area | Residual |
|------|----------|
| Power bleed 0.00085 | Unit PASS |
| Extends / kill-extend | Unit PASS |
| Item magnet / collect line | Unit PASS |
| Sixth Sense rates | Unit PASS |
| Twin / dash / bomb numbers | Unit PASS |
| Gamepad map | Unit PASS |
| Consumable tap + CD | Unit PASS |
| **Graze counter + graze sfx density** | Product pass open |
| **Shot levels / weapon matrix / option shots** | Product pass open |
| **Familiars** | Product pass open |
| **Boss phases, HP, threat, twin AI** | Live play open |
| **Autofire** | Intentional unified **hold-fire** (no separate toggle) — document for players |
| **Cloud progress merge** | Product pass open |
| **Touch input latency / multi-touch** | Product pass open |

---

## P5 — Audio

| Area | Residual |
|------|----------|
| SFX 16 envelopes | Unit PASS |
| YT lofi ID | Shared `rPjez8z61rI` |
| **Soundgate → musicPlay** | Fix session + retries (this ship) |
| Music mute / volume on web | Product pass open |
| Desktop music | No YT; silence unless local asset added |

---

## P6 — Performance

| Area | Residual |
|------|----------|
| llvmpipe probe | Title ~12.5 FPS, play ~7.5 FPS (software GL) |
| Product targets | 60 desktop / 30–45 web — **GPU re-measure open** |
| Caches | Bobina / StageBg caches help; more throttling open |

---

## How to re-verify after fixes

```bash
cd /var/www/dev
npm run export:godot
# hard-refresh https://dev.killallmumus.com/  (or /godot/)
# 1) Soundgate must appear every cold load
# 2) PLAY — FULLSCREEN & SOUND → lofi starts (browser may block if not user gesture)
# 3) Muted path → no lofi, still can play
# 4) Settings music slider moves YT volume

npm run port:dual -- --full --shots core
npm run port:fps   # llvmpipe only
```

---

## Line-by-line audit method (ongoing)

1. Pick HTML function (`musicPlay`, `drawPause`, `useSpecial`, `spawnBoss`, …).  
2. Locate Godot port (`MusicBridge`, `PauseMenu`, `SpecialSystem`, …).  
3. Diff behavior, not just existence (`port:gates` is structure only).  
4. Dual still or headless test when possible.  
5. Check off here only after product eye-pass or unit proof.

**Do not** enable live `USE_GODOT=1` until Phase 7 log in `PARITY.md` is filled with dual + FPS + audio verified.
