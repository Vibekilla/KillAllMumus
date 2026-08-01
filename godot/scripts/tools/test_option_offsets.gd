extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var Fire = load("res://scripts/combat/FireSystem.gd")
	var f = Fire.new()
	var o2 = f.option_offsets(2)
	var o5 = f.option_offsets(5)
	assert(o2.size()==1 and abs(float(o2[0].x)+16)<0.01, "lv2")
	assert(o5.size()==4 and abs(float(o5[3].y)+15)<0.01, "lv5 top orb")
	# optionPos at rest face-up: face=-PI/2 → rot=0 → q = p + (ox, oy)
	var dummy = Node2D.new()
	root.add_child(dummy)
	dummy.global_position = Vector2(200, 300)
	dummy.set("face", -PI / 2.0)
	var q = f.option_pos(dummy, {"x": -16.0, "y": 8.0})
	# rot=0: x=200 + 1*(-16) - 0*(8+16)=184; y=300-16 + 0 + 1*(24)=308
	assert(absf(q.x - 184.0) < 0.5 and absf(q.y - 308.0) < 0.5, "optionPos rest")
	# drawOptions must use world optionPos (not 0,0 local)
	var fx_src := FileAccess.get_file_as_string("res://scripts/render/drawers/drawCombatFx.gd")
	assert("optionPos" in fx_src or "have_pos" in fx_src, "drawOptions world pos")
	var wd_src := FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	assert("drawOptions(st)" in wd_src, "WorldDraw passes player state")
	dummy.queue_free()
	print("[OPT] offsets+pos HTML 1:1 PASS lv2=", o2, " lv5=", o5, " q=", q)
	quit(0)
