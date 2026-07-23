extends Node
## Special ability activation (modular hooks per key).

signal special_used(key: String)

var cooldowns: Dictionary = {}

func can_use(key: String) -> bool:
	return float(cooldowns.get(key, 0.0)) <= 0.0 and GameState.special_meter >= 100.0

func tick(delta: float) -> void:
	for k in cooldowns.keys():
		cooldowns[k] = maxf(0.0, float(cooldowns[k]) - delta)

func use(key: String, player: Node2D, bullet_pool: Node) -> bool:
	if not can_use(key):
		return false
	GameState.special_meter = 0.0
	cooldowns[key] = 8.0
	ProgressStore.estats_add("specials", 1)
	_activate(key, player, bullet_pool)
	special_used.emit(key)
	return true

func _activate(key: String, player: Node2D, bullet_pool: Node) -> void:
	match key:
		"laser", "kraken":
			# Wide beam upward
			if bullet_pool:
				for i in 12:
					var xoff := (i - 5.5) * 18.0
					bullet_pool.spawn(player.global_position + Vector2(xoff, -20), Vector2(0, -600), 3.0, Color(0.65, 0.35, 1.0), 0)
		"bearzooka":
			if bullet_pool:
				for i in 8:
					var a := -PI/2 + (i - 3.5) * 0.12
					bullet_pool.spawn(player.global_position, Vector2.from_angle(a) * 400, 2.5, Color(1.0, 0.6, 0.25), 0)
		"stampede":
			if bullet_pool:
				for i in 6:
					bullet_pool.spawn(player.global_position + Vector2((i-2.5)*30, 0), Vector2(0, -350), 2.0, Color(0.5, 0.85, 0.35), 0)
		"vault":
			# Orbiting clear — wipe nearby enemy bullets
			if bullet_pool:
				bullet_pool.clear_enemy()
		"kiss", "revenge", "void", "badger", "mech", "sixth":
			if bullet_pool:
				bullet_pool.clear_enemy()
				for i in 16:
					var a := TAU * i / 16.0
					bullet_pool.spawn(player.global_position, Vector2.from_angle(a) * 280, 2.0, Color(1.0, 0.4, 0.7), 0)
		_:
			if bullet_pool:
				for i in 10:
					var a := -PI/2 + (i - 4.5) * 0.1
					bullet_pool.spawn(player.global_position, Vector2.from_angle(a) * 450, 2.0, Color(1, 0.8, 0.3), 0)
