extends RefCounted
## 1:1 HTML buildHelp content (tabs + items) — canvas/DOM-free data for Help UI.

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

static func tabs() -> Array:
	return [
		{"id": "controls", "label": "🎮 Controls", "body": _controls()},
		{"id": "weapons", "label": "🔫 Weapons", "body": _weapons()},
		{"id": "specials", "label": "★ Specials", "body": _specials()},
		{"id": "melee", "label": "🗡️ Melee", "body": _melee()},
		{"id": "items", "label": "🎁 Items", "body": _items()},
		{"id": "mechanics", "label": "⚙ Mechanics", "body": _mechanics()},
	]

static func _item(icon: String, name: String, desc: String) -> Dictionary:
	return {"icon": icon, "name": name, "desc": desc}

static func _controls() -> Array:
	return [
		_item("🎮", "Move", "Mouse — she follows the cursor · Arrow keys nudge"),
		_item("🔥", "Shoot", "Hold %s to fire" % MenuHelpers.kb("shoot")),
		_item("💣", "Bomb", MenuHelpers.kb("bomb")),
		_item("⚡", "Special", "%s use · %s cycle" % [MenuHelpers.kb("special"), MenuHelpers.kb("cycle")]),
		_item("🗡", "Melee", "Hold %s to charge · release to slash" % MenuHelpers.kb("melee")),
		_item("🎁", "Items", "%s switch · tap %s to use" % [MenuHelpers.kb("item_switch"), MenuHelpers.kb("item_use")]),
		_item("🎯", "Focus / Dash", "Hold Focus to slow · double-tap to dash"),
		_item("⚙", "Rebind", "Settings → Controls (also Pause)"),
	]

static func _weapons() -> Array:
	var out: Array = []
	var order: Array = DataRegistry.weapon_order if DataRegistry.weapon_order.size() else DataRegistry.weapons.keys()
	for k in order:
		var w: Dictionary = DataRegistry.weapons.get(k, {})
		if w.is_empty() and DataRegistry.weapons.has(str(k)):
			w = DataRegistry.weapons[str(k)]
		out.append(_item(str(w.get("icon", "•")), str(w.get("name", k)), str(w.get("desc", w.get("tag", "")))))
	return out

static func _specials() -> Array:
	var out: Array = []
	for s in DataRegistry.specials:
		out.append(_item(str(s.get("icon", "★")), str(s.get("name", "")), str(s.get("desc", s.get("tag", "")))))
	return out

static func _melee() -> Array:
	var out: Array = []
	for m in DataRegistry.melee:
		out.append(_item(str(m.get("icon", "🗡")), str(m.get("name", "")), str(m.get("tag", m.get("desc", "")))))
	return out

static func _items() -> Array:
	return [
		_item("🅿️", "Power (P)", "Raises shot level. Power bleeds slowly (holds after a boss)."),
		_item("🅿️", "Full Power", "Rare drop that maxes shot level. Bosses leave one."),
		_item("💎", "Point", "Score bonus. Auto-collected near the top (or Focus vacuum)."),
		_item("❤️", "Life Fragment", "5 fragments = 1UP. Every 50 kills also grants a life."),
		_item("💣", "Bomb Fragment", "3 fragments refill a bomb."),
		_item("◈", "Bobo Guard", "Temporary shield that soaks your next hit."),
		_item("★", "Elite Mumus", "Big themed elites — kill for POWER. Banana Frenzy is a shop consumable."),
		_item("💀", "Mumu Skulls", "≈1/16 Mumus drop skulls for Honey Badger’s shop."),
		_item("🍯", "Consumables", "Honeycomb/Wagyu heal · Tears/Souls/Galaxy power · Clover special · Bubbles · Stardust · Vial · Banana · Wormhole. Equip ≤3 in Arsenal. Switch + hold Use (0.8s), 3s CD."),
		_item("🎒", "Arsenal Loadout", "Drag gear into slots (≤5 weapons/specials, 2 melee, 3 items). Locked gear shows 🔒 until bought."),
	]

static func _mechanics() -> Array:
	return [
		_item("💥", "Bomb", "Wipes bullets, damages all foes, brief i-frames."),
		_item("💨", "Dash", "Double-tap Focus toward cursor: i-framed, kills Mumus, rainbow comet."),
		_item("✦", "Slash Dash", "Full-charge melee then dash — slashing super dash."),
		_item("🎯", "Focus", "Slow move + hitbox + vacuum items."),
		_item("⚡", "Special Meter", "Graze & kills charge to 100% · Use / Cycle specials."),
		_item("✨", "Graze", "Skim bullets for score + special charge."),
		_item("💀", "Skulls & Shop", "Spend skulls at Honey Badger after bosses."),
		_item("🌀", "Boss Clear & Portal", "Power drain stops · shop · Interact at portal."),
		_item("🎭", "Bogdanoff Twins", "Only active twin takes damage — wear both down."),
		_item("🏅", "Emblems & Outfits", "Achievements unlock skins · Outfits menu + victory pose."),
		_item("🗑", "Reset Inventory", "Settings → Reset Inventory (keeps Emblems/Outfits/NG+)."),
		_item("🏆", "Rank & Score", "Kills → Rank → mult. HARD ×1.5 · HELL ×2.2 · NG+ stacks."),
	]
