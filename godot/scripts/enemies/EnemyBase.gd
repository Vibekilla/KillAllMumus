extends Area2D
## Mumu / big / elite — HTML spawnLil/spawnBig/spawnElite parity.

signal killed(enemy)

var max_hp: float = 2.0
var hp: float = 2.0
var bullet_pool: Node
var age_frames: float = 0.0
var kind: String = "lil"  # lil | big | elite
var icy: bool = false
var score_value: int = 100
var vel: Vector2 = Vector2.ZERO
var hover_y: float = 0.0
var radius: float = 15.0
var flash: float = 0.0
var charm: float = 0.0
var stun: float = 0.0
var bcol: Color = Color("ff8ac0")
var elite_type: String = ""

const FRAME := 60.0
const TEAM_ENEMY := 1
const BulletPatterns = preload("res://scripts/combat/BulletPatterns.gd")

var ctx: RefCounted
var ported: RefCounted

func _ready() -> void:
	add_to_group("enemies")
	z_index = 15
	z_as_relative = false
	hp = max_hp
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)

func setup(pool: Node, pos: Vector2, opts: Dictionary = {}) -> void:
	bullet_pool = pool
	global_position = pos
	kind = str(opts.get("kind", "lil"))
	icy = bool(opts.get("icy", false))
	max_hp = float(opts.get("hp", 2.0))
	hp = max_hp
	vel = opts.get("vel", Vector2(0, 100)) as Vector2
	radius = float(opts.get("r", 15.0 if kind == "lil" else 22.0))
	score_value = int(opts.get("score", 100 if kind == "lil" else (300 if kind == "big" else 800)))
	hover_y = float(opts.get("hover", Config.playfield().position.y + 90.0))
	elite_type = str(opts.get("elite", ""))
	bcol = Color("9fe0ff") if icy else Color("ff7ad1")
	if kind == "elite":
		bcol = Color("7ed957")
	age_frames = randf() * 100.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	age_frames += delta * FRAME
	if flash > 0.0:
		flash -= delta * FRAME
	var pf: Rect2 = Config.playfield()
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var sfr := 1.0 - GameState.stage_index * 0.13
	var hm := GameState.hard_mode

	if charm > 0.0:
		charm -= delta * FRAME
		if int(age_frames) % 8 == 0:
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == self or not is_instance_valid(o):
					continue
				if o.get("charm") != null and float(o.charm) > 0.0:
					continue
				if global_position.distance_to(o.global_position) < 54.0 and o.has_method("take_damage"):
					o.take_damage(3.0)
		if charm <= 0.0:
			_die(true)
		return

	if stun > 0.0:
		stun -= delta * FRAME
		_touch_player(p)
		return

	if kind == "lil":
		position += vel * delta
		vel.x += sin(age_frames * 0.06 + position.x * 0.01) * 0.05 * FRAME
		if p and position.y < pf.position.y + pf.size.y * 0.6:
			vel.x += signf(p.global_position.x - position.x) * 0.012 * FRAME
		vel.x = clampf(vel.x * 0.99, -2.4 * FRAME, 2.4 * FRAME)
		if position.x < pf.position.x + 12:
			position.x = pf.position.x + 12
			vel.x = absf(vel.x)
		if position.x > pf.end.x - 12:
			position.x = pf.end.x - 12
			vel.x = -absf(vel.x)
		var fire_iv := maxi(70, int(round((150.0 if hm else 190.0) * sfr)))
		if int(age_frames) % fire_iv == 0 and p and position.y < pf.position.y + pf.size.y * 0.7:
			var n := (2 + GameState.stage_index) if icy else (1 + GameState.stage_index)
			BulletPatterns.fan_at(bullet_pool, position.x, position.y, p.global_position.x, p.global_position.y,
				n, 0.5 + GameState.stage_index * 0.12, 2.4 if icy else 2.8, 6.0, "#9fe0ff" if icy else "#ff7ad1")
	else:
		# big / elite — hover and ring-fire
		if position.y < hover_y:
			position.y += vel.y * delta
		else:
			position.y = hover_y + sin(age_frames * 0.05) * 8.0
			var drift := sin(age_frames * 0.02) * 0.9 * FRAME
			if p:
				drift += signf(p.global_position.x - position.x) * 0.4 * FRAME
			position.x += drift * delta
			position.x = clampf(position.x, pf.position.x + 30, pf.end.x - 30)
		var riv := maxi(40, int(round((70.0 if hm else 95.0) * sfr)))
		if int(age_frames) % riv == 0 and p:
			var cnt := (9 if icy else 7) + GameState.stage_index * 2
			BulletPatterns.ring(bullet_pool, position.x, position.y, cnt, 1.7, 6.0, bcol, age_frames * 0.1)
		var hiv := maxi(90, int(round((150.0 if hm else 200.0) * sfr)))
		if int(age_frames) % hiv == 0 and p:
			BulletPatterns.heavy_shell(bullet_pool, position.x, position.y, p.global_position.x, p.global_position.y, 2.5)

	_touch_player(p)

	if position.y > pf.end.y + 50 or position.x < pf.position.x - 60 or position.x > pf.end.x + 60:
		queue_free()
		return
	queue_redraw()

func _touch_player(p: Node2D) -> void:
	if p == null or not p.has_method("take_hit"):
		return
	if global_position.distance_to(p.global_position) < radius + 8.0:
		p.take_hit(2.0 if kind == "elite" else 1.0)

func take_damage(amount: float) -> void:
	hp -= amount
	flash = 5.0
	if hp <= 0.0:
		_die(false)

func _die(charmed: bool = false) -> void:
	# HTML killEnemy parity via ItemSystem
	GameState.add_kill(1)
	if StageFlow:
		StageFlow.note_kill()
	GameState.add_score(int(float(score_value) * GameState.score_mul()))
	if not charmed:
		ItemSystem.kill_enemy({
			"x": global_position.x, "y": global_position.y,
			"kind": kind, "icy": icy,
		}, false)
	else:
		ItemSystem.drop_loot({"x": global_position.x, "y": global_position.y, "kind": kind})
	killed.emit(self)
	queue_free()

func _draw() -> void:
	if ctx == null or ported == null:
		return
	ctx.begin_frame()
	if SimClock and ported.has_method("set_tick"):
		ported.set_tick(SimClock.tick)
	# Local coords: drawers translate by e.x/e.y — pass 0 so body centers on Area2D
	var st := {
		"x": 0.0,
		"y": 0.0,
		"r": radius,
		"t": age_frames,
		"flash": flash,
		"icy": icy,
		"kind": kind,
		"elite": elite_type,
	}
	if kind == "elite":
		ported.draw_elite(st)
	else:
		ported.draw_mumu(st)
