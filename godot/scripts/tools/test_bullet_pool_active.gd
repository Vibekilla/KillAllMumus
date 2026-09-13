extends SceneTree
## Crowd path: live _active list + native drawBullet discs.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var pool := FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if pool.find("var _active") < 0 or pool.find("var _free") < 0:
		print("[POOL] FAIL need _active/_free lists")
		ok = false
	if pool.find("func _compact_inactive") < 0:
		print("[POOL] FAIL need compact of deactivated shots")
		ok = false
	if pool.find("for b in _pool:") >= 0:
		print("[POOL] FAIL sim/draw must not scan the whole 600-slot _pool")
		ok = false
	var bsrc := FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	if bsrc.find("signal deactivated") < 0:
		print("[POOL] FAIL Bullet must emit deactivated")
		ok = false
	var db := FileAccess.get_file_as_string("res://scripts/render/drawers/drawBullet.gd")
	if db.find("fill_circle") < 0:
		print("[POOL] FAIL drawBullet must use fill_circle")
		ok = false
	var p := load("res://scripts/combat/BulletPool.gd")
	if p == null:
		print("[POOL] FAIL BulletPool failed to load")
		ok = false
	if ok:
		print("[POOL] active list + native discs PASS")
		quit(0)
	else:
		print("[POOL] FAIL")
		quit(1)
