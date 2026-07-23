extends Node
## Shop inventory using mumu heads currency.

signal purchased(item: Dictionary)

func heads() -> int:
	return int(ProgressStore.progress.get("heads", 0))

func add_heads(n: int) -> void:
	ProgressStore.progress["heads"] = heads() + n
	ProgressStore.queue_save()

func is_unlocked(kind: String, key: String) -> bool:
	var su: Dictionary = ProgressStore.progress.get("shopUnlocks", {})
	return bool(su.get("%s:%s" % [kind, key], kind == "w" and key == "laser"))

func unlock(kind: String, key: String) -> void:
	var su: Dictionary = ProgressStore.progress.get("shopUnlocks", {})
	su["%s:%s" % [kind, key]] = true
	ProgressStore.progress["shopUnlocks"] = su
	ProgressStore.queue_save()

func list_items(tab: String) -> Array:
	var items: Array = []
	match tab:
		"w":
			for k in DataRegistry.weapons.keys():
				var w: Dictionary = DataRegistry.weapons[k]
				items.append({"kind": "w", "key": k, "name": w.get("name", k), "cost": 30, "icon": w.get("icon", "•")})
		"s":
			for s in DataRegistry.specials:
				items.append({"kind": "s", "key": s.get("key"), "name": s.get("name"), "cost": 40, "icon": s.get("icon", "★")})
		"m":
			for m in DataRegistry.melee:
				items.append({"kind": "m", "key": m.get("key"), "name": m.get("name"), "cost": 35, "icon": m.get("icon", "🗡")})
		"i":
			for c in DataRegistry.consumables:
				items.append({"kind": "i", "key": c.get("key"), "name": c.get("name"), "cost": int(c.get("cost", 20)), "icon": c.get("icon", "•")})
	return items

func buy(tab: String, key: String) -> bool:
	var cost: int = 30
	for it in list_items(tab):
		if str(it.get("key")) == key:
			cost = int(it.get("cost", 30))
			break
	if heads() < cost:
		return false
	ProgressStore.progress["heads"] = heads() - cost
	if tab == "i":
		var consum: Dictionary = ProgressStore.progress.get("consum", {})
		consum[key] = int(consum.get(key, 0)) + 1
		ProgressStore.progress["consum"] = consum
	else:
		unlock(tab, key)
		var ar: Dictionary = ProgressStore.progress.get("arsenal", {"w": [], "s": [], "m": [], "i": []})
		var slot: String = ""
		if tab == "w":
			slot = "w"
		elif tab == "s":
			slot = "s"
		elif tab == "m":
			slot = "m"
		if slot != "":
			var arr: Array = []
			if ar.has(slot) and ar[slot] is Array:
				arr = (ar[slot] as Array).duplicate()
			if key not in arr:
				arr.append(key)
			ar[slot] = arr
			ProgressStore.progress["arsenal"] = ar
			ProgressStore._apply_to_fields()
	ProgressStore.queue_save()
	purchased.emit({"tab": tab, "key": key})
	return true
