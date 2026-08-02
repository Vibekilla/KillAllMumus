extends SceneTree
## HTML pdown taps clear shop (r=38) / portal (r=44) when field cleared.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var main: String = FileAccess.get_file_as_string("res://scripts/main/Main.gd")
	if main.find("_try_clear_gate_pointer") < 0:
		print("[CGATE] FAIL Main must handle clear-gate pointer taps")
		ok = false
	if main.find("38.0") < 0 and main.find("< 38") < 0:
		print("[CGATE] FAIL shop tap radius 38")
		ok = false
	if main.find("44.0") < 0 and main.find("< 44") < 0:
		print("[CGATE] FAIL portal tap radius 44")
		ok = false
	if main.find("enter_shop") < 0 or main.find("enter_portal") < 0:
		print("[CGATE] FAIL must call enter_shop/enter_portal")
		ok = false
	# InputRouter still has keyboard interact radii
	var ir: String = FileAccess.get_file_as_string("res://scripts/input/InputRouter.gd")
	if ir.find("40.0") < 0 and ir.find("40") < 0:
		print("[CGATE] FAIL interact shop radius 40")
		ok = false
	if ir.find("44.0") < 0 and ir.find("44") < 0:
		print("[CGATE] FAIL interact portal radius 44")
		ok = false
	var scr = load("res://scripts/main/Main.gd")
	if scr == null:
		print("[CGATE] FAIL Main.gd parse")
		ok = false
	if ok:
		print("[CGATE] PASS")
		quit(0)
	else:
		print("[CGATE] FAIL")
		quit(1)
