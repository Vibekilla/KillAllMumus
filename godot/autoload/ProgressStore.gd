extends Node
## Local + cloud progress for linked Bobina accounts.

signal progress_loaded
signal progress_saved

var progress: Dictionary = {}
var emblems: Dictionary = {}
var estats: Dictionary = {}
var ng_unlocked: int = 0
var hell_cleared: bool = false

const SAVE_PATH := "user://progress.json"

func _ready() -> void:
	progress = _default()
	_load_local()
	_apply_to_fields()

func _default() -> Dictionary:
	return {
		"v": 1,
		"emblems": {"start": true},
		"estats": {"kills": 0, "graze": 0, "best": 0, "clears": 0, "dashes": 0, "specials": 0, "bombs": 0, "bosses": 0},
		"arsenal": {"w": ["laser"], "s": ["mech", "bearzooka"], "m": ["katana"], "i": ["honeycomb"]},
		"heads": 0,
		"shopUnlocks": {},
		"consum": {},
		"ngUnlocked": 0,
		"hellCleared": false,
		"difficulty": 0,
		"ngPlus": 0,
		"outfit": "og",
		"pose": 0,
		"face": 0,
		"handle": "",
		"settings": {},
	}

func _apply_to_fields() -> void:
	emblems = progress.get("emblems", {"start": true})
	estats = progress.get("estats", {})
	ng_unlocked = int(progress.get("ngUnlocked", 0))
	hell_cleared = bool(progress.get("hellCleared", false))
	GameState.difficulty = int(progress.get("difficulty", 0))
	GameState.ng_plus = mini(ng_unlocked, int(progress.get("ngPlus", 0)))
	GameState.selected_outfit = str(progress.get("outfit", "og"))
	var ar: Dictionary = progress.get("arsenal", {})
	if ar.has("w") and ar["w"] is Array and ar["w"].size():
		GameState.weapons.clear()
		for w in ar["w"]:
			GameState.weapons.append(str(w))
	if ar.has("s") and ar["s"] is Array:
		GameState.specials.clear()
		for s in ar["s"]:
			GameState.specials.append(str(s))

func has_emblem(id: String) -> bool:
	return bool(emblems.get(id, false))

func unlock_emblem(id: String) -> void:
	if emblems.get(id, false):
		return
	emblems[id] = true
	progress["emblems"] = emblems
	queue_save()

func estats_add(key: String, n: int = 1) -> void:
	estats[key] = int(estats.get(key, 0)) + n
	progress["estats"] = estats
	queue_save()

func on_game_cleared(difficulty: int, ng_plus: int, speedrun: bool, no_death: bool, no_bomb: bool) -> void:
	unlock_emblem("clear")
	if difficulty >= 1:
		unlock_emblem("clear_hard")
	if difficulty >= 2:
		unlock_emblem("clear_hell")
		hell_cleared = true
		progress["hellCleared"] = true
	if speedrun:
		unlock_emblem("speedrun")
	if ng_plus > 0:
		unlock_emblem("ngplus")
	if ng_plus >= 3:
		unlock_emblem("ngplus_3")
	if ng_plus >= 25:
		unlock_emblem("ng25")
	if ng_plus >= 50:
		unlock_emblem("ng50")
	if ng_plus >= 75:
		unlock_emblem("ng75")
	if ng_plus >= 100:
		unlock_emblem("ng100")
	if no_death:
		unlock_emblem("no_miss_game")
	if no_bomb:
		unlock_emblem("no_bomb_game")
	estats_add("clears", 1)
	var next_ng := mini(100, ng_plus + 1)
	if next_ng > ng_unlocked:
		ng_unlocked = next_ng
		progress["ngUnlocked"] = ng_unlocked
	queue_save()

func outfit_unlocked(key: String) -> bool:
	for e in DataRegistry.emblems:
		if str(e.get("outfit", "")) == key:
			return has_emblem(str(e.get("id", "")))
	return true

var _save_timer: Timer

func queue_save() -> void:
	if _save_timer == null:
		_save_timer = Timer.new()
		_save_timer.one_shot = true
		_save_timer.wait_time = 0.8
		add_child(_save_timer)
		_save_timer.timeout.connect(_flush_save)
	_save_timer.start()

func _flush_save() -> void:
	progress["emblems"] = emblems
	progress["estats"] = estats
	progress["ngUnlocked"] = ng_unlocked
	progress["hellCleared"] = hell_cleared
	progress["difficulty"] = GameState.difficulty
	progress["ngPlus"] = GameState.ng_plus
	progress["outfit"] = GameState.selected_outfit
	progress["arsenal"] = {
		"w": GameState.weapons.duplicate(),
		"s": GameState.specials.duplicate(),
		"m": progress.get("arsenal", {}).get("m", ["katana"]),
		"i": progress.get("arsenal", {}).get("i", ["honeycomb"]),
	}
	_save_local()
	if ApiClient.is_authenticated():
		ApiClient.put_progress(progress)

func _save_local() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))
		progress_saved.emit()

func _load_local() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		progress = _default()
		progress.merge(parsed, true)
		_apply_to_fields()
		progress_loaded.emit()

func merge_from_cloud(remote: Dictionary) -> void:
	if remote.is_empty():
		return
	# Union emblems
	var rem_em: Dictionary = remote.get("emblems", {})
	for k in rem_em.keys():
		if rem_em[k]:
			emblems[k] = true
	# Max stats
	var rem_st: Dictionary = remote.get("estats", {})
	for k in rem_st.keys():
		estats[k] = maxi(int(estats.get(k, 0)), int(rem_st[k]))
	ng_unlocked = maxi(ng_unlocked, int(remote.get("ngUnlocked", 0)))
	hell_cleared = hell_cleared or bool(remote.get("hellCleared", false))
	progress = remote.duplicate(true)
	progress["emblems"] = emblems
	progress["estats"] = estats
	progress["ngUnlocked"] = ng_unlocked
	progress["hellCleared"] = hell_cleared
	_apply_to_fields()
	_save_local()
	progress_loaded.emit()
