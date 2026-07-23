extends Control
## HTML panel / toasts / pause / touch chrome — ABOVE world entities (CanvasLayer).
## Stage background is drawn by WorldCanvas under Playfield (not here).

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
		GameState.State.STAGE_CLEAR, GameState.State.SHOP
	]
	if playish:
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
	# Panel + overlays only — never full-field stage bg (that covered entities)
	if playish:
		hud.draw_panel()
		hud.draw_emblem_toasts()
	if GameState.state == GameState.State.PAUSED:
		hud.draw_pause_overlay()
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
