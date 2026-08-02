extends Node
## Object pool for bullets + utility ops matching HTML bulletCancel*.

const BulletScene := preload("res://scenes/bullets/Bullet.tscn")
const POOL_SIZE := 600

var _pool: Array = []

func _ready() -> void:
	for i in POOL_SIZE:
		var b = BulletScene.instantiate()
		b.deactivate()
		add_child(b)
		_pool.append(b)

func spawn(pos: Vector2, vel: Vector2, damage: float, color: Color, team: int):
	for b in _pool:
		if not b.active:
			b.activate(pos, vel, damage, color, team)
			if int(team) == 1:
				b.add_to_group("enemy_bullet")
			else:
				if b.is_in_group("enemy_bullet"):
					b.remove_from_group("enemy_bullet")
			return b
	var b2 = BulletScene.instantiate()
	add_child(b2)
	_pool.append(b2)
	b2.activate(pos, vel, damage, color, team)
	if int(team) == 1:
		b2.add_to_group("enemy_bullet")
	return b2

func clear_enemy() -> void:
	## HTML bulletCancelAll — cancel enemy bullets; first 40 drop point items + floaters
	var pts: int = 0
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		var bx: float = b.global_position.x
		var by: float = b.global_position.y
		if ItemSystem:
			ItemSystem.floaters.append({
				"x": bx, "y": by, "life": 22.0, "vy": -0.6, "scale": 0.42,
			})
			if pts < 40:
				ItemSystem.drop_item(bx, by, "point")
				pts += 1
		b.deactivate()

func clear_enemy_near(pos: Vector2, radius: float, drop_points: bool = true) -> void:
	## HTML bulletCancelNear — keep shells with hp>0; cancel others in radius.
	## drop_points=true (default): ≤10 point drops + floaters (big kill, bulletCancelNear).
	## drop_points=false: floaters only (mech shield / special soft cancel — no free score).
	var pts: int = 0
	var r2: float = radius * radius
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		# HTML: if(b.hp>0) return true — durable shells survive cancel
		var bhp: float = 0.0
		if b.get("hp") != null:
			bhp = float(b.get("hp"))
		if bhp > 0.0:
			continue
		var d2: float = b.global_position.distance_squared_to(pos)
		if d2 > r2:
			continue
		var bx: float = b.global_position.x
		var by: float = b.global_position.y
		if ItemSystem:
			if drop_points and pts < 10:
				ItemSystem.drop_item(bx, by, "point")
				pts += 1
			ItemSystem.floaters.append({
				"x": bx, "y": by,
				"life": 18.0 if drop_points else 10.0,
				"vy": -0.5 if drop_points else -0.4,
				"scale": 0.36 if drop_points else 0.28,
			})
		b.deactivate()

func cancel_enemy_in_annulus(pos: Vector2, lo: float, hi: float) -> void:
	## HTML wave special: cancel non-shell bullets where lo < d < hi
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		var bhp: float = 0.0
		if b.get("hp") != null:
			bhp = float(b.get("hp"))
		if bhp > 0.0:
			continue
		var d: float = b.global_position.distance_to(pos)
		if d > lo and d < hi:
			b.deactivate()

func despawn_enemy_near(pos: Vector2, radius: float, floater_life: float = 0.0, floater_scale: float = 0.3) -> void:
	## HTML pure filter: remove ALL enemy bullets in radius (incl. shells).
	## No point drops — hitPlayer death, slashDash, nadeBoom, enemyExplode.
	var r2: float = radius * radius
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		if b.global_position.distance_squared_to(pos) > r2:
			continue
		if floater_life > 0.0 and ItemSystem:
			ItemSystem.floaters.append({
				"x": b.global_position.x,
				"y": b.global_position.y,
				"life": floater_life,
				"vy": -0.5,
				"scale": floater_scale,
			})
		b.deactivate()

func filter_enemy_in_cone(pos: Vector2, radius: float, dir: float, half: float) -> void:
	## HTML burn bullet cancel: d < reach*0.9 && angDiff < half (+ floaters, no points)
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		var dx: float = b.global_position.x - pos.x
		var dy: float = b.global_position.y - pos.y
		var d := sqrt(dx * dx + dy * dy)
		if d > radius:
			continue
		var ang := atan2(dy, dx)
		var ad := absf(wrapf(ang - dir, -PI, PI))
		if ad < half:
			if ItemSystem:
				ItemSystem.floaters.append({
					"x": b.global_position.x, "y": b.global_position.y,
					"life": 10.0, "vy": -0.4, "scale": 0.28,
				})
			b.deactivate()

func clear_all() -> void:
	for b in _pool:
		if b.active:
			b.deactivate()

func iter_active() -> Array:
	## Active bullets for WorldDraw single-pass (HTML bullets/pshots arrays)
	var out: Array = []
	for b in _pool:
		if b.active:
			out.append(b)
	return out

func melee_deflect(origin: Vector2, dir: float, reach: float, half: float, cancel: bool) -> void:
	## HTML doMeleeSwipe bullet filter — cancel drops points (≤28); else shove outward
	var cnt: int = 0
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		var dx: float = b.global_position.x - origin.x
		var dy: float = b.global_position.y - origin.y
		var d: float = sqrt(dx * dx + dy * dy)
		if d < reach + 18.0 and (d < 46.0 or absf(wrapf(atan2(dy, dx) - dir, -PI, PI)) < half + 0.4):
			if cancel or d < 30.0:
				var bx: float = b.global_position.x
				var by: float = b.global_position.y
				if ItemSystem:
					ItemSystem.floaters.append({
						"x": bx, "y": by, "life": 14.0, "vy": -0.5, "scale": 0.34,
					})
					if cnt < 28:
						ItemSystem.drop_item(bx, by, "point")
						cnt += 1
				b.deactivate()
			else:
				# HTML: sp=max(2.6, hypot(vx,vy)) then set direction outward — speeds are px/frame
				var sp_px: float = maxf(2.6, b.velocity.length() / 60.0)
				var nx: float = dx / d if d > 0.5 else 0.0
				var ny: float = dy / d if d > 0.5 else -1.0
				b.velocity = Vector2(nx, ny) * sp_px * 60.0
