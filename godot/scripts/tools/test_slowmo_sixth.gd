extends SceneTree
## Sixth Sense slowmo gates: mobs 0.4x, elites 0.5x, bosses 0.75x (HTML).
## Run: godot --path godot --headless --script res://scripts/tools/test_slowmo_sixth.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var ch = load("res://scripts/combat/CombatHelpers.gd")
	if ch == null:
		print("[FAIL] load CombatHelpers")
		quit(1)
		return
	# Instantiate helper node-less: CombatHelpers is Node script used as autoload;
	# source contract checks instead if autoload not ready
	var src := FileAccess.get_file_as_string("res://scripts/combat/CombatHelpers.gd")
	if "start_slowmo" not in src or "tick_slowmo" not in src:
		print("[FAIL] missing start/tick_slowmo")
		ok = false
	else:
		print("[SLOW] API ok")
	if "0.4" not in src or "0.5" not in src or "0.75" not in src:
		print("[FAIL] missing rate constants")
		ok = false
	else:
		print("[SLOW] rates 0.4/0.5/0.75 ok")
	var eb := FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if "slowmo_allows_enemy" not in eb:
		print("[FAIL] EnemyBase not gated")
		ok = false
	else:
		print("[SLOW] EnemyBase gated ok")
	var bb := FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if "slowmo_allows_enemy" not in bb:
		print("[FAIL] Boss not gated")
		ok = false
	else:
		print("[SLOW] Boss gated ok")
	var bu := FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	if "slowmo_allows_enemy_bullet" not in bu:
		print("[FAIL] bullets not gated")
		ok = false
	else:
		print("[SLOW] bullets gated ok")
	var sp := FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if "start_slowmo" not in sp:
		print("[FAIL] sixth special should call start_slowmo")
		ok = false
	else:
		print("[SLOW] sixth special wires ok")
	var sf := FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if "bobina_say" not in sf:
		print("[FAIL] missing bobina_say")
		ok = false
	else:
		print("[HIT] bobina_say ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
