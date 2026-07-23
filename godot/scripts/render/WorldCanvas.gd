extends Node2D
## World-space canvas under entities — HTML draw order: stage bg → ambience → (entities) → fx.
## Must sit BELOW Playfield/FxLayer so Bobina, mumus, and bullets are visible (1:1 with public/).

var ctx: RefCounted
var hud: RefCounted
var tick: int = 0

func _ready() -> void:
	z_index = 0
	z_as_relative = false
	set_process(true)
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	hud = load("res://scripts/ui/menu/draw_hud.gd").new()
	hud.setup(ctx)
	add_to_group("world_canvas")

var _last_tick: int = -1

func _process(_d: float) -> void:
	var nt := SimClock.tick if SimClock else tick + 1
	if nt == _last_tick:
		return
	_last_tick = nt
	tick = nt
	var playish := GameState.state in [
		GameState.State.PLAY, GameState.State.INTRO, GameState.State.PAUSED,
		GameState.State.STAGE_CLEAR
	]
	if playish:
		queue_redraw()

func _draw() -> void:
	if ctx == null or hud == null:
		return
	var playish := GameState.state in [
		GameState.State.PLAY, GameState.State.INTRO, GameState.State.PAUSED,
		GameState.State.STAGE_CLEAR
	]
	if not playish:
		return
	ctx.begin_frame()
	hud.set_tick(tick)
	# HTML: drawStageBg then drawBossAmbience (then entities, then fx)
	hud.draw_stage_bg()
	if GameState.state == GameState.State.PLAY:
		hud.draw_boss_ambience()
		hud.draw_phase_veil()
		hud.draw_slowmo_fx()
		var tree := get_tree()
		if tree:
			for b in tree.get_nodes_in_group("bosses"):
				if not is_instance_valid(b):
					continue
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
