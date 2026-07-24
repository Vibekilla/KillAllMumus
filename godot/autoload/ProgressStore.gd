extends Node
## Local + cloud progress for linked Bobina accounts.
## HTML: emblemsGot / estats / arsenal / heads / shopUnlocks / consum / ngUnlocked / hellCleared.

signal progress_loaded
signal progress_saved

var progress: Dictionary = {}
var emblems: Dictionary = {}
var estats: Dictionary = {}
var ng_unlocked: int = 0
var hell_cleared: bool = false
## HTML winCabalUnlock — set true when THIS clear just earned Cabal skin
var win_cabal_unlock: bool = false
## HTML `emblems` run-summary badges from computeEmblems()
var run_summary_emblems: Array = []

const SAVE_PATH := "user://progress.json"
const STARTER_ARSENAL := {
	"w": ["laser"],
	"s": ["mech", "bearzooka"],
	"m": ["katana"],
	"i": ["honeycomb", "bulltears", "bullsouls"],
}

func _ready() -> void:
	progress = _default()
	_load_local()
	_apply_to_fields()

func _default() -> Dictionary:
	return {
		"v": 1,
		"emblems": {"start": true},
		"estats": {
			"kills": 0, "graze": 0, "best": 0, "clears": 0,
			"dashes": 0, "specials": 0, "bombs": 0, "bosses": 0,
			"honeycombs": 0, "mkills": 0, "mweps": 0,
		},
		"arsenal": STARTER_ARSENAL.duplicate(true),
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
		"invMigrated": true,
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
	# HTML MOUSE + audio + speedrun prefs
	var st: Dictionary = progress.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		if st.has("follow"):
			var f := float(st["follow"])
			Config.mouse_follow = clampf(f if f > 1.0 else f, 0.35, 1.0)
			if f > 1.0:
				Config.mouse_follow = clampf(f / 100.0, 0.35, 1.0)
		if st.has("mspeed"):
			var s := float(st["mspeed"])
			Config.mouse_speed = clampf(s if s > 2.0 else s, 0.7, 1.6)
			if s > 2.0:
				Config.mouse_speed = clampf(s / 100.0, 0.7, 1.6)
		if st.has("music") and AudioBus:
			var m := float(st["music"])
			AudioBus.set_music_volume((m / 100.0) if m > 1.0 else m)
		if st.has("sfx") and AudioBus:
			var sx := float(st["sfx"])
			AudioBus.set_sfx_volume((sx / 100.0) if sx > 1.0 else sx)
		if st.has("speedrun"):
			GameState.speedrun = bool(st["speedrun"]) if typeof(st["speedrun"]) == TYPE_BOOL else float(st["speedrun"]) > 0.5

# ── HTML hasEmblem / unlockEmblem / saveEmblems ──────────────────────────

func has_emblem(id: String) -> bool:
	return bool(emblems.get(id, false))

func unlock_emblem(id: String) -> void:
	## HTML unlockEmblem — no-op if already owned or unknown id
	if emblems.get(id, false):
		return
	if emblem_def(id).is_empty():
		return
	emblems[id] = true
	progress["emblems"] = emblems
	# HTML emblemToasts queue (one banner at a time)
	var toasts: Array = get_meta("emblem_toasts", []) if has_meta("emblem_toasts") else []
	toasts.append({"id": id, "t": 0.0})
	set_meta("emblem_toasts", toasts)
	if P2Meta:
		P2Meta.new_emblems.append(id)
	if AudioBus:
		AudioBus.sfx("extend")
	save_emblems()

func tick_emblem_toasts(df: float = 1.0) -> void:
	## HTML drawEmblemToasts advances e.t once per frame; keep sim-time here so HUD 30Hz draw doesn't stretch duration
	if not has_meta("emblem_toasts"):
		return
	var toasts: Array = get_meta("emblem_toasts", [])
	if toasts.is_empty():
		return
	var e: Dictionary = toasts[0]
	if typeof(e) != TYPE_DICTIONARY:
		toasts.pop_front()
		set_meta("emblem_toasts", toasts)
		return
	if emblem_def(str(e.get("id", ""))).is_empty():
		toasts.pop_front()
		set_meta("emblem_toasts", toasts)
		return
	e["t"] = float(e.get("t", 0.0)) + df
	toasts[0] = e
	const DUR := 210.0
	if float(e["t"]) >= DUR:
		toasts.pop_front()
	set_meta("emblem_toasts", toasts)

func has_emblem_toasts() -> bool:
	if not has_meta("emblem_toasts"):
		return false
	var toasts: Array = get_meta("emblem_toasts", [])
	return not toasts.is_empty()

func save_emblems() -> void:
	## HTML saveEmblems
	progress["emblems"] = emblems
	queue_save()

# ── HTML saveEstats / estats_add ─────────────────────────────────────────

func estats_add(key: String, n: int = 1) -> void:
	estats[key] = int(estats.get(key, 0)) + n
	progress["estats"] = estats
	queue_save()

func save_estats() -> void:
	## HTML saveEstats
	progress["estats"] = estats
	queue_save()

# ── HTML saveHeads / saveConsum / saveShopUnlocks / saveArsenal ──────────

func heads() -> int:
	return int(progress.get("heads", 0))

func set_heads(n: int) -> void:
	progress["heads"] = maxi(0, n)
	save_heads()

func save_heads() -> void:
	## HTML saveHeads
	queue_save()

func save_consum() -> void:
	## HTML saveConsum
	queue_save()

func save_shop_unlocks() -> void:
	## HTML saveShopUnlocks
	queue_save()

func save_arsenal() -> void:
	## HTML saveArsenal
	queue_save()

func arsenal_arr(type: String) -> Array:
	var ar: Dictionary = progress.get("arsenal", {})
	var a = ar.get(type, [])
	return a.duplicate() if a is Array else []

func set_arsenal_arr(type: String, arr: Array) -> void:
	var ar: Dictionary = progress.get("arsenal", STARTER_ARSENAL.duplicate(true))
	if typeof(ar) != TYPE_DICTIONARY:
		ar = STARTER_ARSENAL.duplicate(true)
	ar[type] = arr
	progress["arsenal"] = ar
	save_arsenal()
	_apply_to_fields()

# ── HTML contentUnlocked / lockCost (also on MenuHelpers) ───────────────

func content_unlocked(type: String, key: String) -> bool:
	## HTML contentUnlocked
	var free := {
		"w:laser": true, "s:mech": true, "s:bearzooka": true, "m:katana": true,
	}
	var fk := "%s:%s" % [type, key]
	if free.get(fk, false):
		return true
	var su: Dictionary = progress.get("shopUnlocks", {})
	if bool(su.get(fk, false)) or bool(su.get(key, false)):
		return true
	# grandfather anything already equipped (w/s/m only)
	if type == "w" or type == "s" or type == "m":
		return arsenal_arr(type).has(key)
	return false

func lock_cost(type: String, key: String) -> int:
	## HTML lockCost — FREE=0, SHOP_COST overrides, else CONTENT_COST
	var free := {
		"w:laser": true, "s:mech": true, "s:bearzooka": true, "m:katana": true,
	}
	if free.get("%s:%s" % [type, key], false):
		return 0
	var overrides := {
		"w:lotus": 60, "w:shock": 60, "s:kraken": 90, "s:void": 90, "m:hammer": 75,
	}
	var k := "%s:%s" % [type, key]
	if overrides.has(k):
		return int(overrides[k])
	var defaults := {"w": 48, "s": 68, "m": 55}
	return int(defaults.get(type, 30))

# ── HTML resetInventory ─────────────────────────────────────────────────

func reset_inventory() -> void:
	## wipe bought gear + carried items + skulls → starter kit; KEEP emblems, outfits & NG+
	progress["shopUnlocks"] = {}
	progress["consum"] = {}
	progress["heads"] = 0
	progress["arsenal"] = STARTER_ARSENAL.duplicate(true)
	progress["invMigrated"] = true
	_apply_to_fields()
	if GameState.state == GameState.State.PLAY or GameState.state == GameState.State.SHOP:
		if P2Meta and P2Meta.has_method("_apply_arsenal_to_run"):
			P2Meta._apply_arsenal_to_run()
	queue_save()

# ── HTML onGameCleared ──────────────────────────────────────────────────

func on_game_cleared(difficulty: int, ng_plus: int, speedrun: bool, no_death: bool, no_bomb: bool) -> void:
	## HTML onGameCleared
	var hell := difficulty >= 2
	var hard := difficulty >= 1
	win_cabal_unlock = hell and not has_emblem("clear_hell")
	unlock_emblem("clear")
	if hard:
		unlock_emblem("clear_hard")
	if hell:
		unlock_emblem("clear_hell")
		if not hell_cleared:
			hell_cleared = true
			progress["hellCleared"] = true
	if speedrun:
		unlock_emblem("speedrun")
	if speedrun and hell:
		unlock_emblem("speedrun_hell")
	if ng_plus > 0:
		unlock_emblem("ngplus")
	if ng_plus >= 3:
		unlock_emblem("ngplus_3")
	if no_death:
		unlock_emblem("no_miss_game")
	if no_bomb:
		unlock_emblem("no_bomb_game")
	estats_add("clears", 1)
	# HTML: winNgLv = min(MAX_NG, ngPlus+1); unlock next NG if higher
	var next_ng := mini(100, ng_plus + 1)
	if next_ng > ng_unlocked and ng_unlocked < 100:
		ng_unlocked = mini(100, next_ng)
		progress["ngUnlocked"] = ng_unlocked
	if ng_plus >= 25:
		unlock_emblem("ng25")
	if ng_plus >= 50:
		unlock_emblem("ng50")
	if ng_plus >= 75:
		unlock_emblem("ng75")
	if ng_plus >= 100:
		unlock_emblem("ng100")
	queue_save()

# ── HTML computeEmblems (run-summary badges, not permanent emblemsGot) ───

func compute_emblems() -> Array:
	## HTML computeEmblems → temporary `emblems` array for end-of-run summary
	run_summary_emblems = []
	var kills_stage := 0
	if ItemSystem:
		kills_stage = int(ItemSystem.kills_this_stage)
	if kills_stage >= 40 or GameState.total_kills >= 120:
		run_summary_emblems.append({"n": "Mumu Exterminator", "d": "High Mumu kill count"})
	if GameState.total_kills >= 260:
		run_summary_emblems.append({"n": "Total Mumu Annihilation", "d": "Extreme total kills"})
	if CombatHelpers and CombatHelpers.shot_level() >= 4:
		run_summary_emblems.append({"n": "Full Power Bobina", "d": "Reached max power"})
	if GameState.state != GameState.State.GAMEOVER \
			and GameState.stage_index >= maxi(0, DataRegistry.stages.size() - 1):
		run_summary_emblems.append({"n": "Bobo Savior + Mumu Slayer", "d": "True ending clear"})
	return run_summary_emblems

# ── HTML outfitUnlocked ─────────────────────────────────────────────────

func outfit_unlocked(key: String) -> bool:
	## HTML outfitUnlocked — outfits earned strictly via their Emblem
	for e in DataRegistry.emblems:
		if str(e.get("outfit", "")) == key:
			return has_emblem(str(e.get("id", "")))
	return true  # no emblem gate → free (e.g. "og")

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
	# Keep arsenal w/s from GameState live loadout; preserve m/i from progress
	var ar: Dictionary = progress.get("arsenal", STARTER_ARSENAL.duplicate(true))
	if typeof(ar) != TYPE_DICTIONARY:
		ar = STARTER_ARSENAL.duplicate(true)
	ar["w"] = GameState.weapons.duplicate()
	ar["s"] = GameState.specials.duplicate()
	if not ar.has("m") or not (ar["m"] is Array) or (ar["m"] as Array).is_empty():
		ar["m"] = ["katana"]
	if not ar.has("i") or not (ar["i"] is Array):
		ar["i"] = STARTER_ARSENAL["i"].duplicate()
	progress["arsenal"] = ar
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

# ── HTML buildProgressSnapshot / applyProgressSnapshot / cloud ──────────

func build_progress_snapshot() -> Dictionary:
	## HTML buildProgressSnapshot
	_flush_fields_to_progress()
	var snap := progress.duplicate(true)
	snap["v"] = 1
	snap["emblems"] = emblems.duplicate(true)
	snap["estats"] = estats.duplicate(true)
	snap["ngUnlocked"] = ng_unlocked
	snap["hellCleared"] = hell_cleared
	snap["difficulty"] = GameState.difficulty
	snap["ngPlus"] = GameState.ng_plus
	snap["outfit"] = GameState.selected_outfit
	snap["speedrun"] = GameState.speedrun
	return snap

func apply_progress_snapshot(p: Dictionary) -> void:
	## HTML applyProgressSnapshot — union/max merge into local
	if p.is_empty():
		return
	merge_from_cloud(p)

func cloud_linked() -> bool:
	## HTML cloudLinked
	return ApiClient != null and ApiClient.is_authenticated()

func schedule_cloud_save(immediate: bool = false) -> void:
	## HTML scheduleCloudSave
	if not cloud_linked():
		return
	if immediate:
		_flush_save()
	else:
		queue_save()

func cloud_pull_and_merge() -> void:
	## HTML cloudPullAndMerge
	if not cloud_linked():
		return
	ApiClient.pull_progress()
	# push local after pull applies (ApiClient.pull → merge_from_cloud → later put)
	ApiClient.put_progress(build_progress_snapshot())

func save_ng_prefs() -> void:
	## HTML saveNgPrefs
	progress["difficulty"] = GameState.difficulty
	progress["ngPlus"] = GameState.ng_plus
	queue_save()

func cabal_unlocked() -> bool:
	## HTML cabalUnlocked
	return has_emblem("clear_hell")

func emblem_count() -> int:
	## HTML emblemCount
	var n := 0
	for e in DataRegistry.emblems:
		if has_emblem(str(e.get("id", ""))):
			n += 1
	return n

func emblem_def(id: String) -> Dictionary:
	## HTML emblemDef
	for e in DataRegistry.emblems:
		if str(e.get("id", "")) == id:
			return e
	return {}

func _flush_fields_to_progress() -> void:
	progress["emblems"] = emblems
	progress["estats"] = estats
	progress["ngUnlocked"] = ng_unlocked
	progress["hellCleared"] = hell_cleared
	progress["difficulty"] = GameState.difficulty
	progress["ngPlus"] = GameState.ng_plus
	progress["outfit"] = GameState.selected_outfit
	var ar: Dictionary = progress.get("arsenal", STARTER_ARSENAL.duplicate(true))
	if typeof(ar) != TYPE_DICTIONARY:
		ar = STARTER_ARSENAL.duplicate(true)
	ar["w"] = GameState.weapons.duplicate()
	ar["s"] = GameState.specials.duplicate()
	progress["arsenal"] = ar

func merge_from_cloud(remote: Dictionary) -> void:
	## HTML applyProgressSnapshot — max/union into local; never replace progress wholesale
	if remote.is_empty():
		return
	# Union emblems
	var rem_em: Dictionary = remote.get("emblems", {})
	if typeof(rem_em) == TYPE_DICTIONARY:
		for k in rem_em.keys():
			if rem_em[k]:
				emblems[k] = true
	# Max stats
	var rem_st: Dictionary = remote.get("estats", {})
	if typeof(rem_st) == TYPE_DICTIONARY:
		for k in rem_st.keys():
			estats[k] = maxi(int(estats.get(k, 0)), int(rem_st[k]))
	if remote.has("ngUnlocked"):
		ng_unlocked = mini(100, maxi(ng_unlocked, int(remote.get("ngUnlocked", 0))))
	if remote.get("hellCleared", false):
		hell_cleared = true
	# Union shop unlocks
	var rem_su: Dictionary = remote.get("shopUnlocks", {})
	var su: Dictionary = progress.get("shopUnlocks", {})
	if typeof(su) != TYPE_DICTIONARY:
		su = {}
	if typeof(rem_su) == TYPE_DICTIONARY:
		for k in rem_su.keys():
			if rem_su[k]:
				su[k] = true
	# Heads: take max
	var heads_local := int(progress.get("heads", 0))
	var heads_remote := int(remote.get("heads", 0)) if remote.has("heads") else heads_local
	# Arsenal: union of keys per slot (multi-device safe; HTML replaces if remote non-empty)
	var ar_local: Dictionary = progress.get("arsenal", STARTER_ARSENAL.duplicate(true))
	if typeof(ar_local) != TYPE_DICTIONARY:
		ar_local = STARTER_ARSENAL.duplicate(true)
	var ar_remote: Dictionary = remote.get("arsenal", {})
	if typeof(ar_remote) != TYPE_DICTIONARY:
		ar_remote = {}
	var merged_ar := {}
	for slot in ["w", "s", "m", "i"]:
		var seen := {}
		var out: Array = []
		for src in [ar_local.get(slot, []), ar_remote.get(slot, [])]:
			if src is Array:
				for x in src:
					var sk := str(x)
					if not seen.get(sk, false):
						seen[sk] = true
						out.append(sk)
		merged_ar[slot] = out if out.size() else STARTER_ARSENAL.get(slot, []).duplicate()
	if (merged_ar.get("w", []) as Array).is_empty():
		merged_ar["w"] = ["laser"]
	# Consum: take max qty per key
	var c_local: Dictionary = progress.get("consum", {})
	var c_remote: Dictionary = remote.get("consum", {})
	if typeof(c_local) != TYPE_DICTIONARY:
		c_local = {}
	if typeof(c_remote) != TYPE_DICTIONARY:
		c_remote = {}
	var merged_c := {}
	for k in c_local.keys():
		merged_c[k] = int(c_local[k])
	for k in c_remote.keys():
		merged_c[k] = maxi(int(merged_c.get(k, 0)), int(c_remote[k]))
	# Settings: shallow-merge (remote fills missing; keep local overrides for present keys)
	var st_local: Dictionary = progress.get("settings", {})
	var st_remote: Dictionary = remote.get("settings", {})
	if typeof(st_local) != TYPE_DICTIONARY:
		st_local = {}
	if typeof(st_remote) == TYPE_DICTIONARY:
		for k in st_remote.keys():
			if not st_local.has(k):
				st_local[k] = st_remote[k]
	# Write back into existing progress (preserve binds/outfit/etc. if remote sparse)
	progress["emblems"] = emblems
	progress["estats"] = estats
	progress["ngUnlocked"] = ng_unlocked
	progress["hellCleared"] = hell_cleared
	progress["shopUnlocks"] = su
	progress["heads"] = maxi(heads_local, heads_remote)
	progress["arsenal"] = merged_ar
	progress["consum"] = merged_c
	progress["settings"] = st_local
	# Prefer higher NG+ / difficulty only if remote is ahead
	if remote.has("ngPlus"):
		GameState.ng_plus = maxi(GameState.ng_plus, int(remote.get("ngPlus", 0)))
		progress["ngPlus"] = GameState.ng_plus
	if remote.has("difficulty"):
		# keep local difficulty preference; only raise ng unlock ladder above
		progress["difficulty"] = GameState.difficulty
	if remote.has("outfit") and str(progress.get("outfit", "")) == "":
		progress["outfit"] = remote.get("outfit")
	_apply_to_fields()
	_save_local()
	progress_loaded.emit()
