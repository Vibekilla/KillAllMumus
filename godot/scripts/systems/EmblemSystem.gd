extends Node
## Emblem unlocks, outfit gating, and per-frame play tick (HTML emblemTick).

func has(id: String) -> bool:
	return ProgressStore.has_emblem(id)

func unlock(id: String) -> void:
	ProgressStore.unlock_emblem(id)

func count() -> int:
	var n := 0
	for e in DataRegistry.emblems:
		if has(str(e.get("id", ""))):
			n += 1
	return n

func total() -> int:
	return DataRegistry.emblems.size()

func outfit_unlocked(key: String) -> bool:
	return ProgressStore.outfit_unlocked(key)

func tick_play() -> void:
	## HTML emblemTick — called every sim step while state==play
	if GameState.state != GameState.State.PLAY:
		return
	if GameState.session_score >= 1_000_000:
		unlock("score_1m")
	if GameState.session_score >= 5_000_000:
		unlock("score_5m")
	if CombatHelpers and CombatHelpers.shot_level() >= 4:
		unlock("full_power")
	if GameState.lives >= 8:
		unlock("life_8")
	if GameState.lives >= CombatHelpers.MAX_LIVES:
		unlock("max_lives")
	if GameState.weapons.size() >= 5:
		unlock("weapon_all")
	if count() >= 20:
		unlock("bride")  # meta: collecting 20 emblems earns the wedding dress
	# keep lifetime best score live
	if GameState.session_score > int(ProgressStore.estats.get("best", 0)):
		ProgressStore.estats["best"] = GameState.session_score
		ProgressStore.progress["estats"] = ProgressStore.estats

func compute_emblems() -> Array:
	## HTML computeEmblems
	return ProgressStore.compute_emblems()

func all_emblems() -> Array:
	return DataRegistry.emblems
