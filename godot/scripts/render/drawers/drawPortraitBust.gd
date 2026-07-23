extends RefCounted
## 1:1 HTML drawPortraitBust — circular frame + clip + IMG/portrait drawer dispatch.
## Source: public/index.html function drawPortraitBust (no simplified stand-ins).

var ctx
var tick: int = 0
var _ape
var _robotnik
var _mumina
var _lily
var _police
var _bogdanoff
var _devil
var _wynn

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func set_drawers(d: Dictionary) -> void:
	_ape = d.get("ape")
	_robotnik = d.get("robotnik")
	_mumina = d.get("mumina")
	_lily = d.get("lily")
	_police = d.get("police")
	_bogdanoff = d.get("bogdanoff")
	_devil = d.get("devil")
	_wynn = d.get("wynn")

func drawPortraitBust(px, py, size, type, color) -> void:
	## Exact HTML order: ring → clip → image/draw* → restore
	ctx.save()
	ctx.translate(float(px), float(py))
	var R: float = float(size) * 0.5
	ctx.fill_style("rgba(10,6,14,0.7)")
	ctx.begin_path()
	ctx.arc(0, 0, R + 4, 0, TAU)
	ctx.fill()
	ctx.stroke_style(color)
	ctx.line_width(2)
	ctx.begin_path()
	ctx.arc(0, 0, R + 4, 0, TAU)
	ctx.stroke()
	ctx.save()
	ctx.begin_path()
	ctx.arc(0, 0, R, 0, TAU)
	ctx.clip()
	var t := str(type)
	if t == "mumina" and AssetBank and AssetBank.ok("mumina"):
		var img = AssetBank.get_tex("mumina")
		var iw := float(img.get_width())
		var ih := float(img.get_height())
		var s := maxf(2.0 * R / iw, 2.0 * R / ih) * 1.06
		var dw := iw * s
		var dh := ih * s
		ctx.draw_image(img, -0.5 * dw, -0.46 * dh, dw, dh)
	elif t == "lily" and AssetBank and AssetBank.ok("lily"):
		var img2 = AssetBank.get_tex("lily")
		var iw2 := float(img2.get_width())
		var ih2 := float(img2.get_height())
		var s2 := maxf(2.0 * R / iw2, 2.0 * R / ih2) * 1.04
		var dw2 := iw2 * s2
		var dh2 := ih2 * s2
		ctx.draw_image(img2, -0.5 * dw2, -0.5 * dh2, dw2, dh2)
	elif t == "bobina":
		# HTML: solid fill; live talk gif is drawn by caller (manageGifOverlays / dialog)
		ctx.fill_style("#2a1830")
		ctx.fill_rect(-R, -R, 2.0 * R, 2.0 * R)
	else:
		var fake := {"r": R * 1.1, "data": {"color": color}, "x": 0, "y": 0, "flash": 0}
		match t:
			"ape":
				if _ape: _ape.drawApe(fake, false)
			"robotnik":
				if _robotnik: _robotnik.drawRobotnik(fake, false)
			"mumina":
				if _mumina: _mumina.drawMumina(fake, false)
			"lily":
				if _lily: _lily.drawLily(fake, false)
			"police":
				if _police: _police.drawPolice(fake, false)
			"bogdanoff":
				if _bogdanoff: _bogdanoff.drawBogdanoff(fake, false)
			"devil":
				if _devil: _devil.drawDevil(fake, false)
			_:
				if _wynn: _wynn.drawWynn(fake, false)
	ctx.restore()
	ctx.restore()
