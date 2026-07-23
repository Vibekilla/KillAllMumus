extends Node
## Shop inventory using mumu heads currency.

signal purchased(item: Dictionary)

func heads() -> int:
	return int(ProgressStore.progress.get("heads", 0))

func add_heads(n: int) -> void:
	ProgressStore.progress["heads"] = heads() + n
	ProgressStore.queue_save()

func is_unlocked(kind: String, key: String) -> bool:
	## HTML contentUnlocked
	return ProgressStore.content_unlocked(kind, key)

func unlock(kind: String, key: String) -> void:
	var su: Dictionary = ProgressStore.progress.get("shopUnlocks", {})
	su["%s:%s" % [kind, key]] = true
	ProgressStore.progress["shopUnlocks"] = su
	ProgressStore.save_shop_unlocks()

func list_items(tab: String) -> Array:
	## HTML shopList
	var items: Array = []
	match tab:
		"w":
			for k in DataRegistry.weapons.keys():
				var w: Dictionary = DataRegistry.weapons[k]
				items.append({
					"kind": "gear", "type": "w", "key": k,
					"name": w.get("name", k), "icon": w.get("icon", "•"),
					"desc": w.get("desc", w.get("tag", "")), "col": w.get("col", "#fff"),
					"owned": ProgressStore.content_unlocked("w", str(k)),
					"cost": ProgressStore.lock_cost("w", str(k)),
				})
		"s":
			for s in DataRegistry.specials:
				var sk := str(s.get("key"))
				items.append({
					"kind": "gear", "type": "s", "key": sk,
					"name": s.get("name"), "icon": s.get("icon", "★"),
					"desc": s.get("desc", s.get("tag", "")), "col": s.get("col", "#fff"),
					"owned": ProgressStore.content_unlocked("s", sk),
					"cost": ProgressStore.lock_cost("s", sk),
				})
		"m":
			for m in DataRegistry.melee:
				var mk := str(m.get("key"))
				items.append({
					"kind": "gear", "type": "m", "key": mk,
					"name": m.get("name"), "icon": m.get("icon", "🗡"),
					"desc": m.get("desc", m.get("tag", "")), "col": m.get("col", "#fff"),
					"owned": ProgressStore.content_unlocked("m", mk),
					"cost": ProgressStore.lock_cost("m", mk),
				})
		"i":
			for c in DataRegistry.consumables:
				var ck := str(c.get("key"))
				items.append({
					"kind": "consumable", "key": ck,
					"name": c.get("name"), "icon": c.get("icon", "•"),
					"desc": c.get("desc", ""), "col": c.get("color", c.get("col", "#fff")),
					"cost": int(c.get("cost", 20)),
					"qty": int(ProgressStore.progress.get("consum", {}).get(ck, 0)),
				})
	return items

func buy(tab: String, key: String) -> bool:
	## HTML shopBuy
	if tab == "i":
		var cost: int = 20
		for c in DataRegistry.consumables:
			if str(c.get("key")) == key:
				cost = int(c.get("cost", 20))
				break
		if heads() < cost:
			return false
		ProgressStore.progress["heads"] = heads() - cost
		ProgressStore.save_heads()
		var consum: Dictionary = ProgressStore.progress.get("consum", {})
		consum[key] = int(consum.get(key, 0)) + 1
		ProgressStore.progress["consum"] = consum
		ProgressStore.save_consum()
		purchased.emit({"tab": tab, "key": key})
		return true
	# gear unlock
	if ProgressStore.content_unlocked(tab, key):
		return false
	var cost2: int = ProgressStore.lock_cost(tab, key)
	if heads() < cost2:
		return false
	ProgressStore.progress["heads"] = heads() - cost2
	ProgressStore.save_heads()
	unlock(tab, key)
	if P2Meta and P2Meta.has_method("_apply_arsenal_to_run"):
		P2Meta._apply_arsenal_to_run()
	purchased.emit({"tab": tab, "key": key})
	return true
