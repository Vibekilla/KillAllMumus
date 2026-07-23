extends RefCounted
## Host for 1:1 HTML draw* ports via CanvasCompat.
## Owns all entity drawers and dispatches with dict state (local coords: x/y often 0).

var ctx
var tick: int = 0
var _bobina
var _mumu
var _elite
var _bullet
var _pshot
var _ape
var _robotnik
var _mumina
var _lily
var _police
var _bogdanoff
var _wynn
var _devil
var _honey
var _title
var _bobo
var _mech
var _item
var _boss
var _fx
var _melee_fx
var _stage_bg
var _fire
var _portrait_bust

func setup(c) -> void:
	ctx = c
	_bobina = _load("res://scripts/render/drawers/drawBobina.gd")
	_mumu = _load("res://scripts/render/drawers/drawMumu.gd")
	_elite = _load("res://scripts/render/drawers/drawElite.gd")
	_bullet = _load("res://scripts/render/drawers/drawBullet.gd")
	_pshot = _load("res://scripts/render/drawers/drawPShot.gd")
	_ape = _load("res://scripts/render/drawers/drawApe.gd")
	_robotnik = _load("res://scripts/render/drawers/drawRobotnik.gd")
	_mumina = _load("res://scripts/render/drawers/drawMumina.gd")
	_lily = _load("res://scripts/render/drawers/drawLily.gd")
	_police = _load("res://scripts/render/drawers/drawPolice.gd")
	_bogdanoff = _load("res://scripts/render/drawers/drawBogdanoff.gd")
	_wynn = _load("res://scripts/render/drawers/drawWynn.gd")
	_devil = _load("res://scripts/render/drawers/drawDevil.gd")
	_honey = _load("res://scripts/render/drawers/drawHoneyBadger.gd")
	_title = _load("res://scripts/render/drawers/drawTitle.gd")
	_bobo = _load("res://scripts/render/drawers/drawBobo.gd")
	_mech = _load("res://scripts/render/drawers/drawMech.gd")
	_item = _load("res://scripts/render/drawers/drawItem.gd")
	_boss = _load("res://scripts/render/drawers/drawBoss.gd")
	_fx = _load("res://scripts/render/drawers/drawFx.gd")
	_melee_fx = _load("res://scripts/render/drawers/drawMeleeFx.gd")
	_stage_bg = _load("res://scripts/render/drawers/drawStageBg.gd")
	_fire = _load("res://scripts/render/drawers/fire.gd")
	_portrait_bust = _load("res://scripts/render/drawers/drawPortraitBust.gd")
	if _title and _bobina and _title.has_method("set_bobina"):
		_title.set_bobina(_bobina)
	var portrait_drawers := {
		"ape": _ape, "robotnik": _robotnik, "mumina": _mumina, "lily": _lily,
		"police": _police, "bogdanoff": _bogdanoff, "devil": _devil, "wynn": _wynn,
	}
	if _boss and _boss.has_method("set_drawers"):
		_boss.set_drawers(portrait_drawers)
	if _portrait_bust and _portrait_bust.has_method("set_drawers"):
		_portrait_bust.set_drawers(portrait_drawers)

func _load(path: String):
	var sc = load(path)
	if sc == null:
		push_warning("PortedDraw: missing %s" % path)
		return null
	if not sc.can_instantiate():
		push_warning("PortedDraw: cannot instantiate %s" % path)
		return null
	var inst = sc.new()
	if inst == null:
		return null
	if inst.has_method("setup"):
		inst.setup(ctx)
	return inst

func set_tick(t: int) -> void:
	tick = t
	for d in [_bobina, _mumu, _elite, _bullet, _pshot, _ape, _robotnik, _mumina, _lily, _police, _bogdanoff, _wynn, _devil, _honey, _title, _boss, _fx, _melee_fx, _stage_bg, _fire]:
		if d and d.has_method("set_tick"):
			d.set_tick(t)

func set_outfit(o: String) -> void:
	if _bobina and _bobina.has_method("set_outfit"):
		_bobina.set_outfit(o)

func draw_bobina(st: Dictionary) -> void:
	if _bobina == null:
		return
	if _bobina.has_method("set_outfit"):
		_bobina.set_outfit(str(st.get("outfit", "og")))
	if _bobina.has_method("set_tick"):
		_bobina.set_tick(int(st.get("tick", tick)))
	_bobina.drawBobina(st)

func draw_mumu(e: Dictionary) -> void:
	if str(e.get("kind", "")) == "elite":
		draw_elite(e)
		return
	if _mumu:
		_mumu.drawMumu(e)

func draw_elite(e: Dictionary) -> void:
	if _elite:
		_elite.drawElite(e)

func draw_bullet(b: Dictionary) -> void:
	if _bullet:
		_bullet.drawBullet(b)

func draw_pshot(s: Dictionary) -> void:
	if _pshot:
		_pshot.drawPShot(s)

func draw_title(st: Dictionary = {}) -> void:
	if _title == null:
		return
	if st.size():
		_title.set_menu_state(st)
	if _bobina and _title.has_method("set_bobina"):
		_title.set_bobina(_bobina)
	_title.set_tick(int(st.get("tick", tick)))
	_title.drawTitle()

func get_title_btns() -> Array:
	if _title:
		return _title.title_btns
	return []

func get_bobina():
	return _bobina

func draw_bobo(cx, cy, sc=1.0, happy=true) -> void:
	if _bobo:
		_bobo.set_tick(tick)
		_bobo.drawBobo(cx, cy, sc, happy)

func draw_mech(x, y, alpha=1.0, rot=0.0) -> void:
	if _mech:
		_mech.set_tick(tick)
		_mech.drawMech(x, y, alpha, rot)

func draw_item(it: Dictionary) -> void:
	if _item:
		_item.set_tick(tick)
		_item.drawItem(it)

func draw_boss(b: Dictionary) -> void:
	## 1:1 HTML drawBoss — via drawBoss.gd only (no alternate implementation)
	if _boss == null:
		push_error("PortedDraw.draw_boss: drawBoss.gd missing — public parity broken")
		return
	_boss.drawBoss(b)

func draw_portrait_bust(px, py, size, type, color) -> void:
	## 1:1 HTML drawPortraitBust
	if _portrait_bust == null:
		push_error("PortedDraw.draw_portrait_bust: drawer missing")
		return
	_portrait_bust.drawPortraitBust(px, py, size, type, color)

func draw_fx(fx_list: Array = []) -> void:
	if _fx and _fx.has_method("drawFx"):
		_fx.drawFx(fx_list)

func draw_melee_fx(melee_fx: Array = [], player: Node = null) -> void:
	if _melee_fx and _melee_fx.has_method("drawMeleeFx"):
		_melee_fx.drawMeleeFx(melee_fx, player)

func draw_stage_bg() -> void:
	if _stage_bg and _stage_bg.has_method("drawStageBg"):
		_stage_bg.drawStageBg()

func fire(player: Node2D = null, pool: Node = null, focus: bool = false) -> void:
	if _fire and _fire.has_method("fire"):
		_fire.fire(player, pool, focus)
