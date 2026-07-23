extends Node2D
## World-space FX: particles, score pops, flash msg, melee swipe weapons.

var ctx: RefCounted
var combat_fx: RefCounted
var item_draw: RefCounted
var ported: RefCounted
var tick: int = 0

func _ready() -> void:
	z_index = 50
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	combat_fx.setup(ctx)
	item_draw = load("res://scripts/render/drawers/drawItem.gd").new()
	item_draw.setup(ctx)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)
	set_process(true)

var _last_tick: int = -1

func _process(delta: float) -> void:
	## Sim-side FX/item updates only — presentation is WorldDraw
	if CombatHelpers:
		CombatHelpers.tick_fx(delta)
	if ItemSystem:
		ItemSystem.tick(delta)

func _draw() -> void:
	## Presentation merged into WorldDraw (HTML draw order).
	pass
