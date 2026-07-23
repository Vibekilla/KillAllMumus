extends Node
## Held consumables cycle + use.

var selected: int = 0

func inventory() -> Dictionary:
	return ProgressStore.progress.get("consum", {})

func keys() -> Array:
	var out: Array = []
	for c in DataRegistry.consumables:
		var k := str(c.get("key", ""))
		if int(inventory().get(k, 0)) > 0:
			out.append(k)
	return out

func qty(key: String) -> int:
	return int(inventory().get(key, 0))

func cycle() -> void:
	var ks := keys()
	if ks.is_empty():
		selected = 0
		return
	selected = (selected + 1) % ks.size()

func selected_key() -> String:
	var ks := keys()
	if ks.is_empty():
		return ""
	return str(ks[clampi(selected, 0, ks.size() - 1)])

func use_selected() -> bool:
	var k := selected_key()
	if k == "" or qty(k) <= 0:
		return false
	var inv := inventory()
	inv[k] = qty(k) - 1
	if inv[k] <= 0:
		inv.erase(k)
	ProgressStore.progress["consum"] = inv
	_apply_effect(k)
	ProgressStore.queue_save()
	return true

func _apply_effect(key: String) -> void:
	match key:
		"honeycomb":
			GameState.lives = mini(GameState.lives + 1, 9)
		"bulltears":
			GameState.bombs = mini(GameState.bombs + 1, 5)
		"bullsouls", "stardust", "galaxygas":
			GameState.special_meter = 100.0
		"wagyu", "banana":
			GameState.power = minf(GameState.power + 1.0, 4.0)
		_:
			GameState.special_meter = minf(100.0, GameState.special_meter + 40.0)
