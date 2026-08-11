extends SceneTree
## HTML honeycomb/wagyu clamp lives — never gainLife 50k overflow.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/systems/ConsumableSystem.gd")
	var apply_i := src.find("func _apply_effect")
	var chunk := src.substr(apply_i, 900) if apply_i >= 0 else ""
	if chunk.find("gain_life()") >= 0 and (chunk.find("honeycomb") >= 0 or chunk.find("wagyu") >= 0):
		# must not use gain_life for honeycomb/wagyu
		var h_i := chunk.find("\"honeycomb\"")
		var w_i := chunk.find("\"wagyu\"")
		var h_chunk := chunk.substr(h_i, 180) if h_i >= 0 else ""
		var w_chunk := chunk.substr(w_i, 220) if w_i >= 0 else ""
		if h_chunk.find("gain_life") >= 0:
			print("[HEAL] FAIL honeycomb must not call gain_life")
			ok = false
		if w_chunk.find("gain_life") >= 0:
			print("[HEAL] FAIL wagyu must not call gain_life")
			ok = false
	if chunk.find("lives + 1") < 0 and chunk.find("lives +1") < 0:
		print("[HEAL] FAIL honeycomb +1 clamp missing")
		ok = false
	else:
		print("[HEAL] honeycomb clamp ok")
	if chunk.find("lives + 3") < 0 and chunk.find("lives +3") < 0:
		print("[HEAL] FAIL wagyu +3 clamp missing")
		ok = false
	else:
		print("[HEAL] wagyu clamp ok")
	if ok:
		print("[HEAL] PASS")
		quit(0)
	else:
		print("[HEAL] FAIL")
		quit(1)
