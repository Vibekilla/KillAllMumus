extends Node
## Loads modular JSON game data from res://data/

var stages: Array = []
var weapons: Dictionary = {}
var specials: Array = []
var melee: Array = []
var outfits: Array = []
var outfit_colors: Dictionary = {}
var outfit_emoji: Dictionary = {}
var emblems: Array = []
var consumables: Array = []
var ranks: Array = []
var bombs: Array = []
var weapon_order: Array = []
var balance: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var st = _load_json("res://data/stages.json")
	stages = st.get("stages", st if st is Array else [])
	weapons = _load_json("res://data/weapons.json")
	specials = _load_json_array("res://data/specials.json")
	melee = _load_json_array("res://data/melee.json")
	bombs = _load_json_array("res://data/bombs.json")
	var o = _load_json("res://data/outfits.json")
	if o.has("outfits"):
		outfits = o["outfits"]
		outfit_colors = o.get("colors", {})
		outfit_emoji = o.get("emoji", {})
	else:
		outfits = o if o is Array else []
	emblems = _load_json_array("res://data/emblems.json")
	consumables = _load_json_array("res://data/consumables.json")
	ranks = _load_json_array("res://data/ranks.json")
	var wo = _load_json("res://data/weapon_order.json")
	weapon_order = wo if wo is Array else []
	balance = _load_json("res://data/balance.json")
	print("[DataRegistry] stages=%d weapons=%d specials=%d outfits=%d emblems=%d consumables=%d" % [
		stages.size(), weapons.size(), specials.size(), outfits.size(), emblems.size(), consumables.size()
	])

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing data file: " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	if typeof(parsed) == TYPE_ARRAY:
		return {"_array": parsed}
	return {}

func _load_json_array(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("_array"):
		return parsed["_array"]
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("stages"):
		return parsed["stages"]
	return []

func get_stage(index: int) -> Dictionary:
	if index < 0 or index >= stages.size():
		return {}
	return stages[index]

func get_weapon(key: String) -> Dictionary:
	return weapons.get(key, {})

func rank_for_kills(kills: int) -> String:
	var r := "D"
	# ranks may be {k,r} from HTML or {kills,rank}
	for entry in ranks:
		var need := int(entry.get("k", entry.get("kills", 0)))
		if kills >= need:
			r = str(entry.get("r", entry.get("rank", "D")))
	return r

func max_lives() -> int:
	return int(balance.get("MAX_LIVES", 9))

func max_bombs() -> int:
	return int(balance.get("MAX_BOMBS", 5))
