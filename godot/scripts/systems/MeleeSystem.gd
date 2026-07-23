extends Node
## Melee swipe / charge.

signal melee_hit(damage: float)

var cooldown: float = 0.0
var charge: float = 0.0
var holding: bool = false

func tick(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if holding:
		charge = minf(1.0, charge + delta * 0.85)
	else:
		charge = maxf(0.0, charge - delta * 2.0)

func begin_hold() -> void:
	holding = true

func release(player: Node2D, melee_key: String) -> void:
	holding = false
	if cooldown > 0.0:
		charge = 0.0
		return
	var def := _def(melee_key)
	var dmg: float = float(def.get("dmg", 6)) * (0.55 + charge * 0.85)
	var reach: float = float(def.get("reach", 150))
	cooldown = float(def.get("cd", 15)) / 60.0
	# Damage nearby enemies in arc
	var origin := player.global_position
	for e in player.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to: Vector2 = e.global_position - origin
		if to.length() <= reach and abs(to.angle_to(Vector2.UP)) < float(def.get("arc", 2.0)) * 0.5:
			if e.has_method("take_damage"):
				e.take_damage(dmg)
				melee_hit.emit(dmg)
	charge = 0.0

func _def(key: String) -> Dictionary:
	for m in DataRegistry.melee:
		if str(m.get("key", "")) == key:
			return m
	return {}
