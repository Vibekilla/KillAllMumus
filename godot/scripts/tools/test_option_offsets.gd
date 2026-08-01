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
	print("[OPT] offsets HTML 1:1 PASS lv2=", o2, " lv5=", o5)
	quit(0)
