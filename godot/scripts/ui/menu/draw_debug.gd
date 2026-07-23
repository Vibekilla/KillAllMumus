extends RefCounted
## 1:1 HTML drawDebugLayer

var ctx
var tick: int = 0
var _last_ms: float = 0.0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func draw_debug_layer() -> void:
	if not Config.debug_layer:
		return
	var now := Time.get_ticks_msec()
	var fps := 0
	if _last_ms > 0.0:
		fps = int(round(1000.0 / maxf(1.0, now - _last_ms)))
	_last_ms = now
	ctx.save()
	# screen-space panel
	ctx.fill_style("rgba(0,0,0,0.55)")
	ctx.fill_rect(8, 8, 210, 92)
	ctx.stroke_style("#7ed957")
	ctx.line_width(1)
	ctx.begin_path()
	ctx.rect(8, 8, 210, 92)
	ctx.stroke()
	ctx.fill_style("#7ed957")
	ctx.font("bold 12px monospace")
	ctx.text_align("left")
	ctx.fill_text("DEBUG", 16, 26)
	ctx.fill_style("#c8f0c8")
	ctx.font("11px monospace")
	var st: String = str(GameState.State.keys()[GameState.state])
	ctx.fill_text("state: %s" % st, 16, 44)
	ctx.fill_text("scale: %d%%  sim: %dHz" % [int(Config.display_scale * 100), Config.refresh_rate], 16, 60)
	ctx.fill_text("canvas: %d×%d" % [int(Config.W), int(Config.H)], 16, 76)
	var p = Engine.get_main_loop().root.get_tree().get_first_node_in_group("player") if Engine.get_main_loop() else null
	if p:
		ctx.fill_text("player: %d,%d  fps≈%d" % [int(p.global_position.x), int(p.global_position.y), fps], 16, 92)
	else:
		ctx.fill_text("fps≈%d" % fps, 16, 92)
	ctx.restore()
