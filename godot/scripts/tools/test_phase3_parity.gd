extends SceneTree
## Phase 3: poseParams / coffeeHold / lerpAngle / melee keys / pOrb constants.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var cf = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	var ch = root.get_node_or_null("/root/CombatHelpers")

	# coffeeHold
	var h0: Dictionary = cf.coffeeHold(0.0)
	if absf(float(h0.y) - 3.0) > 0.01 or absf(float(h0.sip)) > 0.01:
		print("[P3] FAIL coffeeHold t=0 got ", h0); ok = false
	var hpi: Dictionary = cf.coffeeHold(PI / 0.025)  # cos≈-1 → sip≈1
	# t such that cos(t*0.025)=-1 → t*0.025 = PI → t = PI/0.025
	if absf(float(hpi.sip) - 1.0) > 0.05:
		print("[P3] FAIL coffeeHold sip peak got ", hpi.sip); ok = false
	if absf(float(hpi.y) - (3.0 - 7.0)) > 0.2:
		print("[P3] FAIL coffeeHold y at sip1 got ", hpi.y); ok = false

	# poseParams cases
	var p1: Dictionary = cf.poseParams(1, 0.0)
	if str(p1.expr) != "uwu":
		print("[P3] FAIL pose1 expr ", p1.expr); ok = false
	var p2: Dictionary = cf.poseParams(2, 0.0)
	if str(p2.expr) != "annoyed":
		print("[P3] FAIL pose2 expr"); ok = false
	var p3: Dictionary = cf.poseParams(3, 0.0)
	if str(p3.expr) != "smile":
		print("[P3] FAIL pose3 expr"); ok = false
	var p4: Dictionary = cf.poseParams(4, 0.0)
	if str(p4.expr) != "squee":
		print("[P3] FAIL pose4 expr"); ok = false
	var p5: Dictionary = cf.poseParams(5, 0.0)
	if str(p5.expr) != "giggle" or absf(float(p5.lean) - 0.04) > 0.001:
		print("[P3] FAIL pose5 ", p5); ok = false
	var p0: Dictionary = cf.poseParams(0, 0.0)
	if str(p0.expr) != "smile":
		print("[P3] FAIL pose0 expr"); ok = false
	# bounce idle at t=0: (1-cos0)*1.6 = 0
	if absf(float(p0.bounce)) > 0.01:
		print("[P3] FAIL pose0 bounce@0 ", p0.bounce); ok = false
	# dance bounce at t=PI/(2*0.15): sin=1 → bounce=15
	var p1b: Dictionary = cf.poseParams(1, PI / (2.0 * 0.15))
	if absf(float(p1b.bounce) - 15.0) > 0.2:
		print("[P3] FAIL pose1 bounce peak ", p1b.bounce); ok = false

	# lerpAngle
	if ch == null:
		print("[P3] FAIL no CombatHelpers"); ok = false
	else:
		var a: float = float(ch.lerp_angle(0.0, PI * 0.5, 0.5))
		if absf(a - PI * 0.25) > 0.001:
			print("[P3] FAIL lerpAngle mid ", a); ok = false
		# wrap across -PI boundary: short arc midpoint near ±π
		var b: float = float(ch.lerp_angle(PI * 0.9, -PI * 0.9, 0.5))
		if absf(absf(b) - PI) > 0.35:
			print("[P3] FAIL lerpAngle wrap ", b); ok = false

	# source guards
	var dmw: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawCombatFx.gd")
	for k in ["katana", "lash", "scythe", "hammer", "claws"]:
		if dmw.find('key == "%s"' % k) < 0 and dmw.find("key == '%s'" % k) < 0:
			print("[P3] FAIL missing weapon ", k); ok = false
	if dmw.find("ellipse(10, 0, 2.7, 6.6") < 0:
		print("[P3] FAIL katana tsuba ellipse"); ok = false
	if dmw.find("N := 18") < 0 and dmw.find("N = 18") < 0:
		print("[P3] FAIL lash N=18"); ok = false
	if dmw.find("sip < 0.5") < 0:
		print("[P3] FAIL pose steam sip gate"); ok = false
	# pOrb radii
	var bob: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawBobina.gd")
	if bob.find("3.0") < 0 or bob.find("1.3") < 0:
		print("[P3] FAIL pOrb radii"); ok = false
	# limb / circle modules
	if not FileAccess.file_exists("res://scripts/render/drawers/limb.gd"):
		print("[P3] FAIL limb.gd"); ok = false
	if not FileAccess.file_exists("res://scripts/render/drawers/circle.gd"):
		print("[P3] FAIL circle.gd"); ok = false

	if ok:
		print("[P3] Phase 3 render helpers PASS")
		quit(0)
	else:
		print("[P3] FAIL")
		quit(1)
