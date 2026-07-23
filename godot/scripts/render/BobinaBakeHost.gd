extends Node2D
## Host for BobinaDrawCache SubViewport bake — draws one full drawBobina centered.

var _ctx: RefCounted
var _bobina: RefCounted
var _state: Dictionary = {}
var _scale: float = 1.0
var _center: float = 128.0

func configure(ctx: RefCounted, bobina: RefCounted) -> void:
	_ctx = ctx
	_bobina = bobina

func set_bake(state: Dictionary, scale: float, center: float) -> void:
	_state = state
	_scale = scale
	_center = center
	queue_redraw()

func _draw() -> void:
	if _ctx == null or _bobina == null:
		return
	_ctx.begin_frame()
	_ctx.save()
	_ctx.translate(_center, _center)
	_ctx.scale(_scale, _scale)
	var st := {
		"x": 0, "y": 0, "iframe": 0, "focus": false, "walk": 0, "bombFx": 0,
		"face": float(_state.get("face", -PI / 2.0)),
		"vx": float(_state.get("vx", 0)),
		"vy": float(_state.get("vy", 0)),
		"outfit": str(_state.get("outfit", "og")),
		"tick": int(_state.get("tick", 0)),
	}
	if _state.has("expr"):
		st["expr"] = _state["expr"]
	if _state.has("lean"):
		st["lean"] = _state["lean"]
	if _state.has("hold"):
		st["hold"] = _state["hold"]
	if _bobina.has_method("set_outfit"):
		_bobina.set_outfit(str(st["outfit"]))
	if _bobina.has_method("set_tick"):
		_bobina.set_tick(int(st["tick"]))
	_bobina.drawBobina(st)
	_ctx.restore()
