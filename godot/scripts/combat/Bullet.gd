extends Area2D
## Pooled projectile — enemy or player, with HTML pshot flags.

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.ENEMY
var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var lifetime: float = 4.0
var radius: float = 4.0
var color: Color = Color(1, 0.4, 0.6)
var active: bool = false
var grazeable: bool = true
var grazed: bool = false

# HTML pshot / bullet flags
var pshot: bool = false
var home: bool = false
var laser: bool = false
var gat: bool = false
var nade: bool = false
var vrip: bool = false
var petal: bool = false
var zap: bool = false
var pierce: bool = false
var foc: bool = false
var voidbolt: bool = false
var shell: bool = false
var curl: float = 0.0
var wv: float = 0.0
var wph: float = 0.0
var life_frames: float = -1.0
var hp: float = 0.0
var _boomed: bool = false
var hit_ids: Dictionary = {}  # pierce tracking

const FRAME := 60.0

var ctx: RefCounted
var ported: RefCounted

func _ensure_draw() -> void:
	if ctx != null:
		return
	var sc = load("res://scripts/render/CanvasCompat.gd")
	if sc == null:
		push_error("[Bullet] CanvasCompat failed to load")
		return
	ctx = sc.new()
	if ctx == null or not ctx.has_method("bind"):
		ctx = null
		push_error("[Bullet] CanvasCompat.new() failed")
		return
	ctx.bind(self)
	var pd = load("res://scripts/render/PortedDraw.gd")
	if pd:
		ported = pd.new()
		if ported and ported.has_method("setup"):
			ported.setup(ctx)

func activate(pos: Vector2, vel: Vector2, dmg: float, col: Color, t: Team) -> void:
	z_index = 12
	global_position = pos
	velocity = vel
	damage = dmg
	color = col
	team = t
	lifetime = 5.0
	grazed = false
	active = true
	_reset_flags()
	show()
	set_physics_process(true)
	# Never toggle monitoring inside area signals — deferred avoids Godot spam
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	queue_redraw()

func _reset_flags() -> void:
	pshot = false
	home = false
	laser = false
	gat = false
	nade = false
	vrip = false
	petal = false
	zap = false
	pierce = false
	foc = false
	voidbolt = false
	shell = false
	curl = 0.0
	wv = 0.0
	wph = 0.0
	life_frames = -1.0
	hp = 0.0
	_boomed = false
	hit_ids.clear()
	radius = 4.0

func set_props(props: Dictionary) -> void:
	for k in props.keys():
		match str(k):
			"pshot":
				pshot = bool(props[k])
			"home":
				home = bool(props[k])
			"laser":
				laser = bool(props[k])
			"gat":
				gat = bool(props[k])
			"nade":
				nade = bool(props[k])
			"vrip":
				vrip = bool(props[k])
			"petal":
				petal = bool(props[k])
			"zap":
				zap = bool(props[k])
			"pierce":
				pierce = bool(props[k])
			"foc":
				foc = bool(props[k])
			"voidbolt":
				voidbolt = bool(props[k])
			"shell":
				shell = bool(props[k])
			"curl":
				curl = float(props[k])
			"wv":
				wv = float(props[k])
			"wph":
				wph = float(props[k])
			"life":
				life_frames = float(props[k])
			"radius":
				radius = float(props[k])
			"hp":
				hp = float(props[k])
	if gat or laser:
		radius = 3.0
	elif nade:
		radius = 5.0
	elif vrip:
		radius = 5.0
	elif shell:
		radius = 12.0
	queue_redraw()

func deactivate() -> void:
	if nade and not _boomed and pshot:
		_boomed = true
		_nade_boom()
	active = false
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	velocity = Vector2.ZERO
	_reset_flags()

func _nade_boom() -> void:
	ItemSystem.nade_boom(global_position.x, global_position.y)

func _physics_process(delta: float) -> void:
	if not active:
		return
	# homing (HTML: pull toward nearest, clamp speed ~12 px/frame)
	if home:
		var t := _nearest_target()
		if t:
			var a := (t - global_position).angle()
			velocity += Vector2.from_angle(a) * 0.8 * FRAME * FRAME * delta
			var sp := velocity.length()
			if sp > 0.01:
				velocity = velocity * ((12.0 * FRAME) / sp)
	# lotus curl
	if absf(curl) > 0.0001:
		var c := cos(curl)
		var sn := sin(curl)
		var nx := velocity.x * c - velocity.y * sn
		var ny := velocity.x * sn + velocity.y * c
		velocity = Vector2(nx, ny)
	# wave weave
	if wv > 0.0:
		wph += 0.34 * FRAME * delta
		var m := velocity.length()
		if m < 0.01:
			m = 1.0
		var px := -velocity.y / m
		var py := velocity.x / m
		var o := cos(wph) * wv * FRAME
		position += velocity * delta + Vector2(px, py) * o * delta
	else:
		position += velocity * delta

	if life_frames >= 0.0:
		life_frames -= delta * FRAME
		if life_frames <= 0.0:
			deactivate()
			return

	lifetime -= delta
	var pf: Rect2 = Config.playfield()
	if lifetime <= 0.0 or not pf.grow(50).has_point(position):
		deactivate()
		return
	# HTML graze ring: near player, not hit yet
	if team == Team.ENEMY and grazeable and not grazed:
		_try_graze()
	# Visual is local-centered and orientation-independent for fast path — no per-frame redraw

func _try_graze() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var p = tree.get_first_node_in_group("player")
	if p == null:
		return
	var dead_v = p.get("dead")
	if dead_v != null and dead_v:
		return
	var phase_v = p.get("phase_t")
	if phase_v != null and float(phase_v) > 0.0:
		return
	var focus_on := false
	var focus_v = p.get("focus")
	if focus_v != null and focus_v:
		focus_on = true
	var hit_r := 2.2 if focus_on else 4.2
	var rr := radius + hit_r
	var d2 := global_position.distance_squared_to(p.global_position)
	if d2 < rr * rr:
		return  # actual hit handled by area signal
	if d2 < (rr + 8.0) * (rr + 8.0):
		grazed = true
		GameState.graze += 1
		ProgressStore.estats_add("graze", 1)
		var eg := int(ProgressStore.estats.get("graze", 0))
		if eg >= 1000:
			ProgressStore.unlock_emblem("graze_1000")
		if eg >= 5000:
			ProgressStore.unlock_emblem("graze_5000")
		if eg >= 10000:
			ProgressStore.unlock_emblem("graze_10000")
		GameState.add_score(int(12.0 * CombatHelpers.score_mult()))
		GameState.special_meter = minf(100.0, GameState.special_meter + 0.2)
		if AudioBus:
			AudioBus.sfx("graze")
		if CombatHelpers:
			for i in range(2):
				CombatHelpers.particles.append({
					"x": global_position.x, "y": global_position.y,
					"vx": (randf() - 0.5) * 3.0, "vy": (randf() - 0.5) * 3.0,
					"life": 10.0, "c": "#fff",
				})

func _nearest_target() -> Vector2:
	var best := Vector2.ZERO
	var best_d := 1e12
	var found := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e.global_position
			found = true
	return best if found else Vector2.ZERO

func _draw() -> void:
	if not active:
		return
	# Fast path: native CanvasItem draws (CanvasCompat/PortedDraw was ~4fps with 50+ bullets)
	var r := radius
	if team == Team.PLAYER and pshot:
		if laser or foc:
			draw_line(Vector2(0, r * 2.0), Vector2(0, -r * 4.0), color, maxf(2.0, r), true)
			draw_circle(Vector2.ZERO, r * 0.7, color.lightened(0.3))
		elif gat:
			draw_circle(Vector2.ZERO, r * 0.85, color)
			draw_circle(Vector2(-r * 0.3, -r * 0.2), r * 0.35, color.lightened(0.4))
		elif nade:
			draw_circle(Vector2.ZERO, r * 1.15, color.darkened(0.15))
			draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.35, Color(1, 1, 0.7, 0.9))
		elif home:
			draw_circle(Vector2.ZERO, r, color)
			draw_circle(Vector2.ZERO, r * 0.45, color.lightened(0.5))
		else:
			draw_circle(Vector2.ZERO, r, color)
			draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.3, Color(1, 1, 1, 0.55))
		return
	# Enemy bullets
	draw_circle(Vector2.ZERO, r, color)
	draw_circle(Vector2.ZERO, r * 0.55, color.lightened(0.35))
	if hp > 0.0:
		draw_arc(Vector2.ZERO, r + 1.5, 0.0, TAU, 12, color.darkened(0.2), 1.0, true)

func _ready() -> void:
	area_entered.connect(_on_area)

func _on_area(a: Area2D) -> void:
	if not active:
		return
	if team == Team.PLAYER and a.is_in_group("enemies"):
		var id := a.get_instance_id()
		if pierce and hit_ids.has(id):
			return
		if a.has_method("take_damage"):
			a.take_damage(damage)
		if pierce:
			hit_ids[id] = true
		else:
			deactivate()
	elif team == Team.PLAYER and a.is_in_group("enemy_bullet"):
		# shoot down enemy projectiles
		if a.has_method("take_bullet_damage"):
			a.take_bullet_damage(damage)
		elif a.has_method("deactivate"):
			if float(a.get("hp")) > 0.0:
				a.hp -= damage
				if a.hp <= 0.0:
					a.deactivate()
			else:
				a.deactivate()
		if not pierce and not nade:
			deactivate()
	elif team == Team.ENEMY and a.is_in_group("player_hurtbox"):
		var p := a.get_parent()
		if p and p.has_method("take_hit"):
			p.take_hit(damage)
		deactivate()

func take_bullet_damage(amount: float) -> void:
	if not active:
		return
	if hp > 0.0:
		hp -= amount
		if hp <= 0.0:
			deactivate()
	else:
		deactivate()
