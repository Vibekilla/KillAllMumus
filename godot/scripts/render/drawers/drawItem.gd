extends RefCounted
## 1:1 HTML drawItem

var ctx
var tick: int = 0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func drawItem(it: Dictionary) -> void:
	ctx.save()
	ctx.translate(float(it.get("x", 0)), float(it.get("y", 0)))
	var type := str(it.get("type", ""))
	if type == "weapon":
		var wep := str(it.get("wep", "laser"))
		var col := "#ffd27a"
		var glyph := "?"
		if DataRegistry.weapons.has(wep):
			col = str(DataRegistry.weapons[wep].get("col", col))
			glyph = str(DataRegistry.weapons[wep].get("icon", glyph))
		var sz := 11.0
		ctx.shadow_color(col)
		ctx.shadow_blur(10)
		ctx.fill_style(col)
		ctx.save()
		ctx.rotate(PI / 4.0)
		ctx.begin_path()
		ctx.round_rect(-sz, -sz, sz * 2.0, sz * 2.0, 3)
		ctx.fill()
		ctx.restore()
		ctx.shadow_blur(0)
		ctx.fill_style("#1a0e14")
		ctx.font("bold 13px monospace")
		ctx.text_align("center")
		ctx.fill_text(glyph, 0, 1)
		ctx.fill_style(col)
		ctx.font("bold 7px monospace")
		ctx.fill_text("WPN", 0, -15)
		ctx.text_align("left")
		ctx.restore()
		return
	if type == "skull":
		ctx.shadow_color("#ffe0a0")
		ctx.shadow_blur(8)
		ctx.fill_style("#f2ead6")
		ctx.begin_path()
		ctx.arc(0, -1, 6, PI, 0)
		ctx.line_to(5, 3)
		ctx.quadratic_curve_to(5, 6.4, 2, 6.4)
		ctx.line_to(2, 4.6)
		ctx.line_to(-2, 4.6)
		ctx.line_to(-2, 6.4)
		ctx.quadratic_curve_to(-5, 6.4, -5, 3)
		ctx.close_path()
		ctx.fill()
		ctx.shadow_blur(0)
		ctx.fill_style("#241812")
		ctx.begin_path()
		ctx.arc(-2.4, -1, 1.7, 0, TAU)
		ctx.arc(2.4, -1, 1.7, 0, TAU)
		ctx.fill()
		ctx.begin_path()
		ctx.move_to(0, 1.4)
		ctx.line_to(-1, 3.2)
		ctx.line_to(1, 3.2)
		ctx.close_path()
		ctx.fill()
		ctx.restore()
		return
	var map := {
		"power": ["#ff5b8d", "P"],
		"point": ["#5bb8ff", "★"],
		"life": ["#ff6ec7", "♥"],
		"bomb": ["#ffd27a", "✸"],
		"fullpower": ["#ffd27a", "P"],
		"shield": ["#e8a860", "◈"],
		"rapid": ["#ffe14a", "»"],
	}
	var m: Array = map.get(type, ["#fff", "?"])
	var sz2 := 11.0 if type == "fullpower" else 8.0
	ctx.shadow_color(str(m[0]))
	ctx.shadow_blur(8)
	ctx.fill_style(str(m[0]))
	ctx.begin_path()
	ctx.round_rect(-sz2, -sz2, sz2 * 2.0, sz2 * 2.0, 3)
	ctx.fill()
	ctx.shadow_blur(0)
	ctx.fill_style("#1a0e14")
	ctx.font("bold %dpx monospace" % int(sz2 + 2))
	ctx.text_align("center")
	ctx.fill_text(str(m[1]), 0, 1)
	ctx.text_align("left")
	ctx.restore()
