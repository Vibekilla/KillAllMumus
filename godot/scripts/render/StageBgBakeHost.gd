extends Node2D
## Host for StageBgDrawCache SubViewport bake — full drawStageBg in PF-local space.

var _ctx: RefCounted
var _drawer: RefCounted
var _tick: int = 0
var _pf: Rect2 = Rect2(48, 14, 512, 516)

func configure(ctx: RefCounted, drawer: RefCounted) -> void:
	_ctx = ctx
	_drawer = drawer

func set_bake(tick: int, pf: Rect2) -> void:
	_tick = tick
	_pf = pf
	queue_redraw()

func _draw() -> void:
	if _ctx == null or _drawer == null:
		return
	_ctx.begin_frame()
	# Drawer paints in world/PF coords; shift so PF origin → (0,0) in the viewport.
	_ctx.save()
	_ctx.translate(-_pf.position.x, -_pf.position.y)
	if _drawer.has_method("set_tick"):
		_drawer.set_tick(_tick)
	if _drawer.has_method("drawStageBg"):
		_drawer.drawStageBg()
	_ctx.restore()
