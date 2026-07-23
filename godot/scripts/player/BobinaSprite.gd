extends Node2D
## Play-time Bobina renderer.
## Full HTML drawBobina (~4k CanvasCompat ops/frame) tanks Web to ~4 FPS.
## Fast native CanvasItem path keeps ~60 FPS; outfit tint still applies.

var outfit_key: String = "og"
var player_state: Dictionary = {}
## Set true only for offline pixel-parity QA (not for Web)
var use_full_drawbobina: bool = false

var ctx: RefCounted
var ported: RefCounted
var combat_fx: RefCounted
var _last_tick: int = -1

func _ready() -> void:
	z_index = 25
	z_as_relative = false
	# Lazy-load heavy drawers only if full path enabled
	if use_full_drawbobina:
		ctx = load("res://scripts/render/CanvasCompat.gd").new()
		ctx.bind(self)
		ported = load("res://scripts/render/PortedDraw.gd").new()
		ported.setup(ctx)
		combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
		combat_fx.setup(ctx)
	var parent := get_parent()
	if parent:
		parent.z_index = 25
		for c in parent.get_children():
			if c != self and (c is Polygon2D or c is Sprite2D):
				c.visible = false
	queue_redraw()

func set_outfit(key: String) -> void:
	outfit_key = key
	player_state["outfit"] = key
	queue_redraw()

func set_state(st: Dictionary) -> void:
	player_state = st
	if st.has("outfit"):
		outfit_key = str(st["outfit"])
	queue_redraw()

func _process(_delta: float) -> void:
	var nt := int(SimClock.tick) if SimClock else _last_tick + 1
	if nt == _last_tick:
		return
	_last_tick = nt
	player_state["tick"] = nt
	# Native path is cheap — redraw every sim tick for smooth walk bob
	queue_redraw()

func _outfit_color() -> Color:
	var col := Color(1.0, 0.72, 0.82)
	if DataRegistry and DataRegistry.outfit_colors.has(outfit_key):
		var oc = DataRegistry.outfit_colors[outfit_key]
		if oc is String and str(oc).begins_with("#"):
			return Color.html(str(oc))
		if oc is Array and oc.size() > 0 and str(oc[0]).begins_with("#"):
			return Color.html(str(oc[0]))
		if oc is Dictionary and oc.has("body"):
			return Color.html(str(oc["body"]))
	return col

func _draw() -> void:
	if use_full_drawbobina and ctx != null and ported != null:
		_draw_full()
		return
	_draw_fast()

func _draw_full() -> void:
	ctx.begin_frame()
	var st := player_state.duplicate()
	st["outfit"] = outfit_key
	if not st.has("x"):
		st["x"] = 0.0
	if not st.has("y"):
		st["y"] = 0.0
	var t := int(SimClock.tick) if SimClock else 0
	st["tick"] = t
	if ported.has_method("set_tick"):
		ported.set_tick(t)
	if combat_fx:
		combat_fx.set_tick(t)
		if GameState.state == GameState.State.PLAY:
			combat_fx.draw_power_radiance(st)
			combat_fx.draw_power_aura(st)
			combat_fx.draw_dash_comet(st)
	ported.draw_bobina(st)
	if combat_fx and GameState.state == GameState.State.PLAY:
		combat_fx.draw_options(true)

func _draw_fast() -> void:
	## Readable Bobina stand-in: body + head + ears + eyes + walk bob + focus core
	var t := float(player_state.get("tick", 0))
	var focus := bool(player_state.get("focus", false))
	var inv := float(player_state.get("iframe", player_state.get("invuln", 0)))
	var vx := float(player_state.get("vx", 0))
	var bob := sin(t * 0.35) * 1.2
	if absf(vx) > 10.0:
		bob = sin(t * 0.55) * 2.0
	var col := _outfit_color()
	if inv > 0.0 and int(t / 3.0) % 2 == 0:
		col = col.lightened(0.5)
	# shadow
	draw_circle(Vector2(0, 14 + bob * 0.2), 9.0, Color(0, 0, 0, 0.22))
	# legs
	var leg := col.darkened(0.15)
	draw_circle(Vector2(-4.5, 10 + bob), 3.2, leg)
	draw_circle(Vector2(4.5, 10 - bob * 0.6), 3.2, leg)
	# body
	draw_circle(Vector2(0, 2 + bob * 0.3), 11.0, col.darkened(0.08))
	draw_circle(Vector2(0, 1 + bob * 0.3), 10.0, col)
	# head
	draw_circle(Vector2(0, -10 + bob), 9.0, col.lightened(0.05))
	# ears
	var ear := col.darkened(0.05)
	draw_circle(Vector2(-7, -17 + bob), 4.2, ear)
	draw_circle(Vector2(7, -17 + bob), 4.2, ear)
	draw_circle(Vector2(-7, -17 + bob), 2.2, col.lightened(0.25))
	draw_circle(Vector2(7, -17 + bob), 2.2, col.lightened(0.25))
	# eyes
	draw_circle(Vector2(-3.2, -10.5 + bob), 1.6, Color(0.08, 0.04, 0.1))
	draw_circle(Vector2(3.2, -10.5 + bob), 1.6, Color(0.08, 0.04, 0.1))
	draw_circle(Vector2(-2.8, -11.0 + bob), 0.55, Color(1, 1, 1, 0.85))
	draw_circle(Vector2(3.6, -11.0 + bob), 0.55, Color(1, 1, 1, 0.85))
	# arms
	draw_circle(Vector2(-11, 1 + bob), 3.0, col.darkened(0.05))
	draw_circle(Vector2(11, 1 - bob * 0.5), 3.0, col.darkened(0.05))
	# focus hitbox indicator (HTML focus tight core)
	if focus:
		draw_arc(Vector2(0, 2), 4.5, 0.0, TAU, 16, Color(1.0, 0.4, 0.7, 0.85), 1.5, true)
		draw_circle(Vector2(0, 2), 2.0, Color(1.0, 0.85, 0.95, 0.9))
	# power glow
	var powv := float(GameState.power) if GameState else 1.0
	if powv > 2.0:
		var a := clampf((powv - 1.0) / 5.0, 0.0, 0.35)
		draw_arc(Vector2(0, 0), 16.0 + sin(t * 0.2) * 1.5, 0.0, TAU, 24, Color(1.0, 0.5, 0.8, a), 2.0, true)
