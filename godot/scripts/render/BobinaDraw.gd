extends Node2D
## 1:1 Bobina drawer host — uses CanvasCompat + ported draw routines.
## Full drawBobina from HTML is applied via PortedDraw.

var ctx: CanvasCompat
var ported: RefCounted
var player_state: Dictionary = {}

func _ready() -> void:
	ctx = CanvasCompat.new()
	ctx.bind(self)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	if ported.has_method("setup"):
		ported.setup(ctx)

func set_player_state(st: Dictionary) -> void:
	player_state = st
	queue_redraw()

func _draw() -> void:
	if ctx == null:
		return
	ctx.begin_frame()
	if ported and ported.has_method("drawBobina"):
		ported.drawBobina(player_state)
