extends SceneTree
## Servitor hunt AI, laser beam cancel, bombdrop boss dmg, mech optionShot.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var sp: String = FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if sp.find("func _servitor_tick") < 0:
		print("[SV] FAIL missing _servitor_tick")
		ok = false
	if sp.find("d > 62.0") < 0 and sp.find("d > 62") < 0:
		print("[SV] FAIL servitor approach threshold 62 missing")
		ok = false
	if sp.find("voidbolt") < 0:
		print("[SV] FAIL voidbolt shots missing")
		ok = false
	if sp.find("func _laser_tick") < 0:
		print("[SV] FAIL _laser_tick missing")
		ok = false
	if sp.find("func _bombdrop_explode") < 0:
		print("[SV] FAIL bombdrop explode missing")
		ok = false
	if sp.find("take_damage(6.0)") < 0 and sp.find("take_damage(6)") < 0:
		print("[SV] FAIL bombdrop boss dmg 6 missing")
		ok = false
	if sp.find("option_shot") < 0:
		print("[SV] FAIL mech must use FireSystem.option_shot")
		ok = false
	# servitor must not only orbit player
	var si := sp.find("\"servitor\":")
	var se := sp.find("\"kiss\":", si)
	if si >= 0 and se > si:
		var body := sp.substr(si, se - si)
		if body.find("cos(a2) * 42") >= 0 or body.find("cos(a2)*42") >= 0:
			print("[SV] FAIL servitor still orbit-only (not hunting)")
			ok = false
	if ok:
		print("[SV] PASS")
		quit(0)
	else:
		print("[SV] FAIL")
		quit(1)
