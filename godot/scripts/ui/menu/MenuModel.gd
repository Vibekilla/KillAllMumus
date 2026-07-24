extends RefCounted
const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")
## Shared mutable state for canvas menus (mirrors HTML globals).

var outfit_preview: String = "og"
var outfit_pose: int = 0
var victory_face: int = 0
## Dual-only: when >= 0, leaderboard mini Bobina uses VICTORY_FACES[i].expr (HUD ~0.46 scale)
var dual_hud_face: int = -1
var outfit_anim_t: int = 0
var ars_tab: String = "w"
var ars_drag = null  # Dictionary or null
var ars_msg = null
var arsenal_return: String = "title"
var em_page: int = 0
var lb_page: int = 0
var lb_cache: Array = []
var lb_state: String = "idle"  # idle|loading|ok|error
var last_submit = null

# Hit targets rebuilt each frame by drawers
var title_btns: Array = []
var outfit_tiles: Array = []
var outfit_back_btn = null
var outfit_pose_btn = null
var face_btn = null
var ng_tiles: Array = []
var ng_back_btn = null
var em_prev_btn = null
var em_next_btn = null
var arsenal_tiles: Array = []
var lb_rows: Array = []
var lb_prev_btn = null
var lb_next_btn = null
var menu_btn = null

func reset_hits() -> void:
	title_btns.clear()
	outfit_tiles.clear()
	outfit_back_btn = null
	outfit_pose_btn = null
	face_btn = null
	ng_tiles.clear()
	ng_back_btn = null
	em_prev_btn = null
	em_next_btn = null
	arsenal_tiles.clear()
	lb_rows.clear()
	lb_prev_btn = null
	lb_next_btn = null
	menu_btn = null

func load_prefs() -> void:
	outfit_preview = GameState.selected_outfit
	outfit_pose = int(ProgressStore.progress.get("pose", 0))
	victory_face = int(ProgressStore.progress.get("face", 0))

func ars_arr(type: String) -> Array:
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var key = type
	var a: Array = ar.get(key, [])
	if a is Array:
		return a.duplicate()
	return []

func ars_set(type: String, arr: Array) -> void:
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	if typeof(ar) != TYPE_DICTIONARY:
		ar = {}
	ar[type] = arr
	ProgressStore.progress["arsenal"] = ar
	# sync run weapons/specials
	if type == "w":
		GameState.weapons.clear()
		for w in arr:
			GameState.weapons.append(str(w))
		if GameState.weapons.size():
			GameState.current_weapon = GameState.weapons[0]
	elif type == "s":
		GameState.specials.clear()
		for s in arr:
			GameState.specials.append(str(s))
	ProgressStore.queue_save()

func ars_item_by_key(type: String, k: String) -> Dictionary:
	if type == "w":
		if DataRegistry.weapons.has(k):
			var w: Dictionary = DataRegistry.weapons[k].duplicate()
			w["key"] = k
			return w
		return {}
	if type == "s":
		for s in DataRegistry.specials:
			if str(s.get("key")) == k:
				return s
		return {}
	if type == "m":
		for m in DataRegistry.melee:
			if str(m.get("key")) == k:
				return m
		return {}
	for c in DataRegistry.consumables:
		if str(c.get("key")) == k:
			return c
	return {}

func ars_pool(type: String) -> Array:
	var out: Array = []
	if type == "i":
		for c in DataRegistry.consumables:
			var it: Dictionary = c.duplicate()
			it["locked"] = false
			if not it.has("col") and it.has("color"):
				it["col"] = it["color"]
			out.append(it)
		return out
	if type == "w":
		var order: Array = DataRegistry.weapon_order
		if order.is_empty():
			order = DataRegistry.weapons.keys()
		for k in order:
			var it = ars_item_by_key("w", str(k))
			if it.is_empty():
				continue
			it["locked"] = not MenuHelpers.content_unlocked("w", str(k))
			out.append(it)
		return out
	if type == "s":
		for s in DataRegistry.specials:
			var it: Dictionary = s.duplicate()
			it["locked"] = not MenuHelpers.content_unlocked("s", str(it.get("key")))
			out.append(it)
		return out
	for m in DataRegistry.melee:
		var it2: Dictionary = m.duplicate()
		it2["locked"] = not MenuHelpers.content_unlocked("m", str(it2.get("key")))
		out.append(it2)
	return out

func drop_to_slot(type: String, key: String, slot: int) -> void:
	var arr = ars_arr(type)
	var cap: int = int(MenuHelpers.ARS_CAP.get(type, 5))
	var was = arr.find(key)
	if was >= 0:
		arr.remove_at(was)
		slot = clampi(slot, 0, arr.size())
		arr.insert(slot, key)
	elif arr.size() < cap:
		slot = clampi(slot, 0, arr.size())
		arr.insert(slot, key)
	else:
		var s = clampi(slot, 0, arr.size() - 1)
		arr[s] = key
	ars_set(type, arr)

func unequip_slot(type: String, slot: int) -> void:
	var arr = ars_arr(type)
	var min_keep = 0 if type == "s" or type == "i" else 1
	if slot < 0 or slot >= arr.size():
		return
	if arr.size() <= min_keep:
		return
	arr.remove_at(slot)
	ars_set(type, arr)

func toggle_equip(type: String, key: String) -> void:
	var arr = ars_arr(type)
	var cap: int = int(MenuHelpers.ARS_CAP.get(type, 5))
	var min_keep = 0 if type == "s" or type == "i" else 1
	var i = arr.find(key)
	if i >= 0:
		if arr.size() > min_keep:
			arr.remove_at(i)
			ars_set(type, arr)
			if AudioBus:
				AudioBus.sfx("item")
		elif AudioBus:
			AudioBus.sfx("hit")
	else:
		if arr.size() < cap:
			arr.append(key)
			ars_set(type, arr)
			if AudioBus:
				AudioBus.sfx("power")
		elif AudioBus:
			AudioBus.sfx("hit")

func lb_page_count() -> int:
	return maxi(1, int(ceili(float(lb_cache.size()) / float(MenuHelpers.LB_PER_PAGE))))

func set_lb_page(n: int) -> void:
	## HTML lbSetPage
	lb_page = clampi(n, 0, lb_page_count() - 1)

func lb_set_page(n: int) -> void:
	set_lb_page(n)
