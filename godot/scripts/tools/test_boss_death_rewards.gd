extends SceneTree
## HTML boss death: emblems + loot rain only — no free life/bomb/flat score.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	var i := src.find("func _on_hp_zero")
	var chunk := src.substr(i, 1200) if i >= 0 else ""
	if chunk.find("lives + 1") >= 0 or chunk.find("lives+") >= 0:
		print("[BDEATH] FAIL free life on boss death")
		ok = false
	else:
		print("[BDEATH] no free life ok")
	if chunk.find("bombs + 1") >= 0 or chunk.find("bombs+") >= 0:
		print("[BDEATH] FAIL free bomb on boss death")
		ok = false
	else:
		print("[BDEATH] no free bomb ok")
	if chunk.find("add_score") >= 0:
		print("[BDEATH] FAIL flat score on boss death (HTML uses loot only)")
		ok = false
	else:
		print("[BDEATH] no flat score ok")
	if chunk.find("boss_first") < 0 or chunk.find("estats_add(\"bosses\"") < 0:
		print("[BDEATH] FAIL missing emblem/estats path")
		ok = false
	else:
		print("[BDEATH] emblems ok")
	if src.find("_drop_death_loot") < 0:
		print("[BDEATH] FAIL missing death loot rain")
		ok = false
	else:
		print("[BDEATH] loot rain ok")
	if ok:
		print("[BDEATH] PASS")
		quit(0)
	else:
		print("[BDEATH] FAIL")
		quit(1)
