extends SceneTree
## Vault wave hit-once / bull-badger speeds / screen shake / stageclear arsenal.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var sp: String = FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if sp.find("func _wave_ring_tick") < 0:
		print("[WAVES] FAIL missing _wave_ring_tick")
		ok = false
	if sp.find("take_damage(14.0") < 0 and sp.find("14.0 if is_boss") < 0:
		print("[WAVES] FAIL wave boss dmg 14 missing")
		ok = false
	if sp.find("9.5 * df") < 0 and sp.find("9.5*df") < 0:
		print("[WAVES] FAIL bull speed y-=9.5 missing")
		ok = false
	if sp.find("12.0 * df") < 0 and sp.find("* 12.0 * df") < 0:
		print("[WAVES] FAIL badger speed dir*12 missing")
		ok = false
	if sp.find("func _tentacle_tick") < 0:
		print("[WAVES] FAIL tentacle tick missing")
		ok = false
	var bp: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if bp.find("func cancel_enemy_in_annulus") < 0:
		print("[WAVES] FAIL annulus bullet cancel missing")
		ok = false
	var wd: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if wd.find("screen_shake") < 0 or wd.find("0.85") < 0:
		print("[WAVES] FAIL WorldDraw must apply screen_shake * 0.85")
		ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("sfx(\"claw\")") < 0 and pl.find("sfx('claw')") < 0:
		print("[WAVES] FAIL flurry claw sfx missing")
		ok = false
	var fl: String = FileAccess.get_file_as_string("res://scripts/ui/FlowUI.gd")
	if fl.find("_stage_clear_click") < 0 or fl.find("sc_arsenal_btn") < 0:
		print("[WAVES] FAIL stageclear arsenal click missing")
		ok = false
	var df: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_flow.gd")
	if df.find("sc_arsenal_btn") < 0:
		print("[WAVES] FAIL sc_arsenal_btn rect missing")
		ok = false
	if ok:
		print("[WAVES] PASS")
		quit(0)
	else:
		print("[WAVES] FAIL")
		quit(1)
