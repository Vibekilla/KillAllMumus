extends RefCounted
## 1:1 port of HTML "circle" — generated from tools/port/extracted/functions/circle.js
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



func circle(x, y, r, fill, line) -> void:
	ctx.begin_path()
	ctx.arc(x, y, r, 0, 7)
	if line:
		ctx.stroke_style(line)
		ctx.line_width(2)
		ctx.stroke()
	ctx.fill_style(fill)
	ctx.fill()
