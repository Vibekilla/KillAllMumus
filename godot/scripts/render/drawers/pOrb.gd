extends RefCounted
## 1:1 port of HTML "pOrb" — generated from tools/port/extracted/functions/pOrb.js
## No placeholders: full canvas draw path via CanvasCompat.

var ctx
var tick: int = 0
var selected_outfit: String = "og"
var EAR_HIDE := {
	"neko": true, "monke": true, "kigurumi": true, "cheese": true, "cabal": true,
	"badger": true, "viking": true, "samurai": true, "bullbina": true, "jester": true,
	"succubus": true, "squirrely": true, "banana": true,
}
# shared arm state (HTML nested closures)
var _armCol = "#5f3823"
var _armW: float = 3.8
var _handCols = null
var _hold = null
var _armSw: float = 0.0
var _sBob: float = 0.0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func set_outfit(o: String) -> void:
	selected_outfit = o



func pOrb(x, y, glow, c1, c2) -> void:
	ctx.save()
	ctx.shadow_color(glow)
	ctx.shadow_blur(8)
	ctx.fill_style(c1)
	ctx.begin_path()
	ctx.arc(x, y, 3, 0, 7)
	ctx.fill()
	ctx.fill_style(c2)
	ctx.begin_path()
	ctx.arc(x, y, 1.3, 0, 7)
	ctx.fill()
	ctx.restore()
