extends SceneTree
## HTML bearzooka: 3 bombdrops per ct%5, volley vx ±1.5 px/frame.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	# Prefer the updateFx branch (carpet loop), not the name table / activate spawn
	var i := src.find("HTML: for(d=0;d<3;d++)")
	if i < 0:
		i = src.find("for _d in range(3)")
	var chunk := src.substr(maxi(0, i - 40), 700) if i >= 0 else ""
	if chunk.find("range(3)") < 0 and chunk.find("for _d in range(3)") < 0:
		print("[BZ] FAIL must spawn 3 bombdrops")
		ok = false
	else:
		print("[BZ] 3 bombdrops ok")
	if chunk.find("72.0") < 0 and chunk.find("* 72") < 0:
		print("[BZ] FAIL bombdrop x spread should be ±36 (span 72)")
		ok = false
	else:
		print("[BZ] drop spread ok")
	if chunk.find("randf_range(-1.5, 1.5)") < 0 and chunk.find("-1.5, 1.5") < 0:
		print("[BZ] FAIL volley vx must be ±1.5 px/frame")
		ok = false
	else:
		print("[BZ] volley vx ok")
	if ok:
		print("[BZ] PASS")
		quit(0)
	else:
		print("[BZ] FAIL")
		quit(1)
