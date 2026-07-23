extends Control
## Canvas HUD: stage bg, boss ambience, panel, toasts, veil/slowmo, pause.

var ctx: RefCounted
var hud: RefCounted
var debug_draw: RefCounted
var touch_draw: RefCounted
var tick: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	z_index = 5
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_to_group("hud_canvas")
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	hud = load("res://scripts/ui/menu/draw_hud.gd").new()
	hud.setup(ctx)
	debug_draw = load("res://scripts/ui/menu/draw_debug.gd").new()
	debug_draw.setup(ctx)
	touch_draw = load("res://scripts/ui/menu/draw_touch.gd").new()
	touch_draw.setup(ctx)
	GameState.state_changed.connect(func(_s): queue_redraw())
	visible = true

func _process(_d: float) -> void:
	if SimClock:
		tick = SimClock.tick
	var playish := GameState.state in [
		GameState.State.PLAY, GameState.State.INTRO, GameState.State.PAUSED,
		GameState.State.STAGE_CLEAR
	]
	# always redraw while playing for bg animation
	if playish or GameState.state == GameState.State.SHOP:
		queue_redraw()

func _draw() -> void:
	if ctx == null or hud == null:
		return
	ctx.begin_frame()
	hud.set_tick(tick)
	var playish := GameState.state in [
		GameState.State.PLAY, GameState.State.INTRO, GameState.State.PAUSED,
		GameState.State.STAGE_CLEAR
	]
	if playish:
		hud.draw_stage_bg()
		if GameState.state == GameState.State.PLAY:
			hud.draw_boss_ambience()
			hud.draw_phase_veil()
			hud.draw_slowmo_fx()
			# hell portal if boss has hell fields
			var bosses := get_tree().get_nodes_in_group("bosses")
			for b in bosses:
				var hell_r := float(b.get("hellR")) if b.get("hellR") != null else 0.0
				var hell_on := bool(b.get("hell")) if b.get("hell") != null else false
				if hell_on or hell_r > 1.0:
					var rad := float(b.get("radius")) if b.get("radius") != null else 40.0
					var ht := float(b.get("t")) if b.get("t") != null else float(tick)
					hud.draw_hell_portal({
						"x": b.global_position.x, "y": b.global_position.y,
						"hellR": hell_r if hell_r > 1.0 else rad,
						"hellT": ht,
						"hy": b.global_position.y,
					})
		hud.draw_panel()
		hud.draw_emblem_toasts()
	if GameState.state == GameState.State.PAUSED:
		hud.draw_pause_overlay()
	# HTML #touch chrome — virtual stick + action rail (on top of HUD)
	if touch_draw and GameState.state == GameState.State.PLAY:
		touch_draw.set_tick(tick)
		touch_draw.draw()
	if Config.debug_layer and debug_draw and debug_draw.has_method("draw_debug_layer"):
		debug_draw.set_tick(tick)
		debug_draw.draw_debug_layer()

func touch_hit(pos: Vector2) -> String:
	if touch_draw and touch_draw.has_method("hit_key"):
		return str(touch_draw.hit_key(pos))
	return ""
