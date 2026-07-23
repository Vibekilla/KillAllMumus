extends Node2D
## Outfit-aware Bobina renderer — drawBobina + power aura / options / dash comet / pose props.

var outfit_key: String = "og"
var player_state: Dictionary = {}
var ctx: RefCounted
var ported: RefCounted
var combat_fx: RefCounted

func _ready() -> void:
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	combat_fx.setup(ctx)
	var parent := get_parent()
	if parent:
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
	if SimClock:
		player_state["tick"] = SimClock.tick
	queue_redraw()

func _draw() -> void:
	if ctx == null or ported == null:
		return
	ctx.begin_frame()
	var st := player_state.duplicate()
	st["outfit"] = outfit_key
	if not st.has("x"):
		st["x"] = 0.0
	if not st.has("y"):
		st["y"] = 0.0
	var t := 0
	if SimClock:
		t = SimClock.tick
		st["tick"] = t
		if ported.has_method("set_tick"):
			ported.set_tick(t)
		if combat_fx:
			combat_fx.set_tick(t)
	# Underlays: power radiance + aura + dash (local space, trail points local)
	if combat_fx and GameState.state == GameState.State.PLAY:
		combat_fx.draw_power_radiance(st)
		combat_fx.draw_power_aura(st)
		combat_fx.draw_dash_comet(st)
	# Bobina body
	ported.draw_bobina(st)
	# Options familiars
	if combat_fx and GameState.state == GameState.State.PLAY:
		combat_fx.draw_options(true)
	# Pose prop (This Is Fine) if pose set
	if combat_fx and st.has("pose"):
		combat_fx.draw_pose_prop(int(st.get("pose", 0)), float(t))
