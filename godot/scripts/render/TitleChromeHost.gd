extends Node2D
## Host for title static chrome bake (wordmark glow, buttons, social). Live particles / Bobina / start blink stay on TitleScreen.

var _ctx: RefCounted
var _drawer: RefCounted

func configure(ctx: RefCounted, drawer: RefCounted) -> void:
	_ctx = ctx
	_drawer = drawer

func set_bake() -> void:
	queue_redraw()

func _draw() -> void:
	if _ctx == null or _drawer == null:
		return
	_ctx.bind(self)
	_ctx.begin_frame()
	if _drawer.has_method("drawTitleChrome"):
		_drawer.drawTitleChrome()
