extends SceneTree
## Boss body knock shove + dash offx/offy mouse resume parity.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var boss: String = FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if boss.find("knock = 6") < 0 and boss.find("knock = 6.0") < 0:
		print("[BKNOCK] FAIL boss must set player.knock=6 on contact")
		ok = false
	if boss.find("4.5 * FRAME") < 0 and boss.find("4.5*FRAME") < 0:
		print("[BKNOCK] FAIL boss knock velocity nx*4.5 missing")
		ok = false
	if boss.find("var _push") < 0 and boss.find("_push: bool") < 0:
		print("[BKNOCK] FAIL b._push one-shot hit sfx missing")
		ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("var offx") < 0 or pl.find("var offy") < 0:
		print("[BKNOCK] FAIL dash offx/offy fields missing")
		ok = false
	if pl.find("offx *= 0.95") < 0:
		print("[BKNOCK] FAIL offx decay 0.95 missing")
		ok = false
	if pl.find("mouse.x + offx") < 0 and pl.find("mouse.x+offx") < 0:
		print("[BKNOCK] FAIL mouse target must include offx")
		ok = false
	# double-tap window 15 (HTML lastShiftTap<15)
	if pl.find("_shift_tap_t < 15") < 0 and pl.find("_shift_tap_t < 15.0") < 0:
		print("[BKNOCK] FAIL dash double-tap window should be 15 frames")
		ok = false
	# mouse follow must NOT multiply by mouse_speed (HTML only applies speed to keyboard)
	# Find mouse follow block: should have f * FRAME without spd_mul after target
	if pl.find("MOUSE.speed does NOT apply") < 0 and pl.find("does NOT apply here") < 0:
		# structural: mouse path uses f * FRAME only
		if pl.find("* f * FRAME") < 0 and pl.find("*f*FRAME") < 0:
			print("[BKNOCK] FAIL mouse follow velocity form")
			ok = false
	if ok:
		print("[BKNOCK] PASS")
		quit(0)
	else:
		print("[BKNOCK] FAIL")
		quit(1)
