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
	## HTML buildHelp: Move, then one row per BIND_LIST entry (label + that key only).
	var rows := [
		["", "Move", "Mouse — she follows the cursor · Arrow keys nudge"],
		["shoot", "Fire", ""],
		["focus", "Focus / Dash", ""],
		["melee", "Melee (hold=charge)", ""],
		["meleeswap", "Switch Melee", ""],
		["bomb", "Bomb", ""],
		["swap", "Swap Weapon", ""],
		["special", "Use Special", ""],
		["cycle", "Cycle Special", ""],
		["item_switch", "Switch Item", ""],
		["item_use", "Use Item (tap)", ""],
		["interact", "Interact / Shop", ""],
		["pause", "Pause", ""],
	]
	var out: Array = []
	for r in rows:
		var desc := str(r[2])
		if desc == "":
			desc = MenuHelpers.kb(str(r[0]))
		out.append(_item("", str(r[1]), desc))
	out.append(_item("🎮", "Rebind anything", "Tune the mouse feel & change any key in Settings → Controls (also on the Pause screen)."))
	return out

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
	## HTML buildHelp items. Use is a tap: update() consumes on the key edge, and BIND_LIST says "Use Item (tap)".
	## The help paragraph still says HOLD ~0.8s; that sentence is stale against the live code.
	return [
		_item("🅿️", "Power (P)", "Raises your shot level — grab them to power up. Power bleeds off slowly (but holds steady after a boss), so keep collecting."),
		_item("🅿️", "Full Power", "A rare drop that instantly maxes your shot level. Bosses always leave one behind."),
		_item("💎", "Point", "Score bonus. Auto-collected when you fly near the top of the field (or Focus to vacuum them)."),
		_item("❤️", "Life Fragment", "Collect 5 for a 1UP. Every 50 Mumu kills also grants an extra life."),
		_item("💣", "Bomb Fragment", "Collect 3 to refill a bomb."),
		_item("◈", "Bobo Guard", "A temporary shield that soaks your next hit for free. Occasionally dropped by tougher foes."),
		_item("★", "Elite Mumus", "Each stage has a big themed elite — a tank. Take it down for a hefty POWER boost (a few elites will max you out). Monke’s Frenzy is now the Banana consumable at the shop, not a field drop."),
		_item("💀", "Mumu Skulls", "About 1 in 16 Mumus drops a skull — grab them and spend at Honey Badger’s shop after each boss on gear unlocks + consumables. Skulls are scarcer now and gear costs more, so choose your buys."),
		_item("🍯", "Consumables", "Buy items at the shop — Honeycomb/Wagyu (heal), Bull Tears/Bull Souls/Galaxy Gas (power), Clover (special charge), Bubbles (trap Mumus then pop for AoE), Stardust (stars that sap nearby Mumus), Unholy Vial (soaks 3 bullets / 5s), Banana (Monke’s Frenzy rapid fire) & Wormhole (phase 3s — untouchable but you still hurt Mumus) — then equip up to 3 in your Item slots (Arsenal). In a run: tap Switch Item to pick one, tap Use Item to consume — then a 3s cooldown before the next one."),
		_item("🎒", "Arsenal Loadout", "Drag weapons, specials, melee & items into your loadout slots (main menu or between stages) — up to 5 weapons/specials, 2 melee, 3 items. You begin with a starter kit; locked gear shows a 🔒 and a price until you buy it at the shop."),
	]

static func _mechanics() -> Array:
	return [
		_item("💥", "Bomb", "Wipes every bullet on screen, damages all enemies and the boss, and makes you briefly invincible. Limited charges — grab bomb fragments."),
		_item("💨", "Dash", "Double-tap your Focus key to blink toward your cursor: i-framed, kills any Mumu you pass through, and leaves a psychedelic comet."),
		_item("✦", "Slash Dash", "FULLY charge your melee, then double-tap Focus: a supercharged slashing dash that cuts a swath through enemies + bullets."),
		_item("🎯", "Focus", "Hold Focus to slow down for tight dodging and reveal your tiny hitbox; it also vacuums nearby items."),
		_item("⚡", "Special Meter", "Grazing bullets and killing Mumus charges your Special meter. At 100% press Use Special to unleash it, or Cycle Special to switch which one is armed."),
		_item("✨", "Graze", "Skim enemy bullets without getting hit to earn score and charge your Special meter faster."),
		_item("💀", "Skulls & the Shop", "About 1 in 16 Mumus drops a 💀 skull. After each boss, enter Honey Badger’s shop (press Interact) to spend them: unlock weapons, specials & melee — then equip them in the Arsenal — or stock consumables."),
		_item("🌀", "Boss Clear & Portal", "Beat a boss and the arena clears — your power stops draining so you can regroup. Use consumables, visit the shop, then press Interact at the portal to advance to the next stage."),
		_item("🎭", "The Bogdanoff Twins", "Stage 6’s twin boss shares one fight: only the active twin can be damaged, and they trade places whenever they please. Wear BOTH down to clear."),
		_item("🏅", "Emblems & Outfits", "Emblems are achievements — each one unlocks a cosmetic Outfit. Browse skins in the Outfits menu, where you can also choose the victory pose she strikes on a stage clear."),
		_item("🗑", "Reset Inventory", "Settings → Reset Inventory wipes your bought gear, items and skulls back to the starter kit. Your Emblems, Outfits and New Game+ progress are always kept."),
		_item("🏆", "Rank & Score", "More kills → higher Rank → bigger score multiplier. HARD ×1.5, HELL ×2.2, and New Game+ stacks on top."),
	]
