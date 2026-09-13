extends SceneTree
## Shots follow travel heading; mouse follow uses canvas-space cursor (not viewport CSS pixels).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var pl := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	var main := FileAccess.get_file_as_string("res://scripts/main/Main.gd")
	if pl.find("atan2(vpf.y, vpf.x)") < 0:
		print("[AIM] FAIL face lerp must use atan2(vy,vx) like HTML")
		ok = false
	if pl.find("var vpf :=") < 0:
		print("[AIM] FAIL missing vpf px/frame")
		ok = false
	# Duplicate `var vpf` in one function would fail to parse
	var first := pl.find("var vpf :=")
	var second := pl.find("var vpf :=", first + 1)
	if second >= 0:
		print("[AIM] FAIL duplicate var vpf (parse error)")
		ok = false
	if pl.find("pointer_down") < 0 or pl.find("not is_touch") < 0:
		print("[AIM] FAIL pOK must be pointer.down && !touch (HTML)")
		ok = false
	if main.find("func _canvas_pos") < 0:
		print("[AIM] FAIL Main must map screen→canvas (web CSS stretch)")
		ok = false
	if main.find("get_global_mouse_position()") < 0:
		print("[AIM] FAIL Main mouse must use canvas coords")
		ok = false
	if main.find("get_viewport().get_mouse_position()") >= 0:
		print("[AIM] FAIL Main must not feed viewport pixels into JoyPad.pmove")
		ok = false
	var scr = load("res://scripts/player/Player.gd")
	if scr == null:
		print("[AIM] FAIL Player.gd failed to load")
		ok = false
	if ok:
		print("[AIM] canvas mouse + travel heading PASS")
		quit(0)
	else:
		print("[AIM] FAIL")
		quit(1)
