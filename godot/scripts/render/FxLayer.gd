extends Node2D
## World-space FX: particles, score pops, flash msg, melee swipe weapons.
## Simulation advances only on SimClock fixed steps (not display rate).

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
	if SimClock:
		if not SimClock.sim_tick.is_connected(_on_sim_tick):
			SimClock.sim_tick.connect(_on_sim_tick)

func _on_sim_tick(dt: float) -> void:
	## One HTML sim frame — fixed SIM_DT from SimClock.
	if CombatHelpers:
		CombatHelpers.tick_fx(dt)
	if ItemSystem:
		ItemSystem.tick(dt)
	if SimClock:
		tick = SimClock.sim_frame

func _draw() -> void:
	## Presentation merged into WorldDraw (HTML draw order).
	pass
