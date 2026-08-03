extends SceneTree
## Enemies must not fire / body-hit while player.dead (HTML !p.dead).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var eb: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if eb.find("p_alive") < 0:
		print("[EDEAD] FAIL missing p_alive gate for fire/drift")
		ok = false
	if eb.find('bool(p.get("dead"))') < 0 and eb.find("p.get(\"dead\")") < 0:
		print("[EDEAD] FAIL _touch_player must skip when dead")
		ok = false
	if eb.find("p_alive and position.y") < 0 and eb.find("p_alive and") < 0:
		print("[EDEAD] FAIL fire paths should use p_alive")
		ok = false
	# ring fire gated
	if eb.find("% riv == 0 and p_alive") < 0 and eb.find("% riv") >= 0 and eb.find("p_alive") < 0:
		print("[EDEAD] FAIL ring fire not gated")
		ok = false
	var scr = load("res://scripts/enemies/EnemyBase.gd")
	if scr == null:
		print("[EDEAD] FAIL parse")
		ok = false
	if ok:
		print("[EDEAD] PASS")
		quit(0)
	else:
		print("[EDEAD] FAIL")
		quit(1)
