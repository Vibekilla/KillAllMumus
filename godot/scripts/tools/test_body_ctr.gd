extends SceneTree
## HTML bodyCtr(p) = { x:p.x-sin(r)*16, y:(p.y-16)+cos(r)*16 }, r=face+π/2
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var CH = load("res://scripts/combat/CombatHelpers.gd")
	# CombatHelpers is autoload — use root
	var h = root.get_node_or_null("/root/CombatHelpers")
	if h == null:
		print("[BC] FAIL no CombatHelpers")
		quit(1)
		return
	var face = -PI / 2.0  # up
	var r = face + PI / 2.0  # 0
	var expect = Vector2(100.0 - sin(r) * 16.0, (200.0 - 16.0) + cos(r) * 16.0)
	var got: Vector2 = h.body_ctr({"x": 100.0, "y": 200.0, "face": face})
	if got.distance_to(expect) > 0.01:
		print("[BC] FAIL up face got=", got, " expect=", expect)
		quit(1)
		return
	face = 0.0  # right
	r = face + PI / 2.0
	expect = Vector2(100.0 - sin(r) * 16.0, (200.0 - 16.0) + cos(r) * 16.0)
	got = h.body_ctr({"x": 100.0, "y": 200.0, "face": face})
	if got.distance_to(expect) > 0.01:
		print("[BC] FAIL right face got=", got, " expect=", expect)
		quit(1)
		return
	print("[BC] bodyCtr HTML 1:1 PASS")
	quit(0)
