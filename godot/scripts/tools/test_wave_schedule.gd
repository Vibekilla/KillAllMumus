extends SceneTree
## HTML spawnWaves: if(st%iv!==0) return; roll=(st/iv)|0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/enemies/EnemySpawner.gd")
	if src.find("_next_spawn_at") >= 0:
		print("[WAVE] FAIL still using cumulative _next_spawn_at")
		ok = false
	else:
		print("[WAVE] no cumulative next-at ok")
	if src.find("% iv") < 0 and src.find("%iv") < 0:
		print("[WAVE] FAIL missing st % iv gate")
		ok = false
	else:
		print("[WAVE] st%iv gate ok")
	if src.find("st_i / iv") < 0 and src.find("st / iv") < 0:
		print("[WAVE] FAIL roll must be st/iv")
		ok = false
	else:
		print("[WAVE] roll=st/iv ok")
	# first pack is not frame 1 when iv~70 — roll at st=iv is 1
	if src.find("first pack immediately") >= 0:
		print("[WAVE] FAIL still documents immediate first pack")
		ok = false
	if ok:
		print("[WAVE] PASS")
		quit(0)
	else:
		print("[WAVE] FAIL")
		quit(1)
