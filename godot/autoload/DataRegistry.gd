extends Node
## Loads modular JSON game data from res://data/

var stages: Array = []
var weapons: Dictionary = {}
var specials: Array = []
var melee: Array = []
var outfits: Array = []
var emblems: Array = []
var consumables: Array = []
var ranks: Array = []

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	stages = _load_json("res://data/stages.json").get("stages", [])
	weapons = _load_json("res://data/weapons.json")
	specials = _load_json_array("res://data/specials.json")
	melee = _load_json_array("res://data/melee.json")
	outfits = _load_json_array("res://data/outfits.json")
	emblems = _load_json_array("res://data/emblems.json")
	consumables = _load_json_array("res://data/consumables.json")
	ranks = _load_json_array("res://data/ranks.json")
	print("[DataRegistry] stages=%d weapons=%d specials=%d outfits=%d emblems=%d" % [
		stages.size(), weapons.size(), specials.size(), outfits.size(), emblems.size()
	])

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing data file: " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _load_json_array(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing data file: " + path)
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_ARRAY else []

func get_stage(index: int) -> Dictionary:
	if index < 0 or index >= stages.size():
		return {}
	return stages[index]

func get_weapon(key: String) -> Dictionary:
	return weapons.get(key, {})

func rank_for_kills(kills: int) -> String:
	var r := "D"
	for entry in ranks:
		if kills >= int(entry.get("kills", 0)):
			r = str(entry.get("rank", "D"))
	return r
