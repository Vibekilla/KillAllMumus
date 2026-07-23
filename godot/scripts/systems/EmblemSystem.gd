extends Node
## Emblem unlocks & outfit gating.

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
	if GameState.state != GameState.State.PLAY:
		return
	if GameState.session_score >= 1_000_000:
		unlock("score_1m")
	if GameState.session_score >= 5_000_000:
		unlock("score_5m")
	if count() >= 20:
		unlock("bride")

func all_emblems() -> Array:
	return DataRegistry.emblems
