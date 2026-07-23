extends Control

@onready var list: ItemList = %List
@onready var heads_l: Label = %HeadsLabel
@onready var status: Label = %Status

var tab := "w"
var shop: Node

func _ready() -> void:
	visible = false
	shop = preload("res://scripts/systems/ShopSystem.gd").new()
	add_child(shop)
	GameState.state_changed.connect(func(s):
		visible = (s == &"SHOP")
		if visible: _refresh()
	)

func _refresh() -> void:
	heads_l.text = "💀 Heads: %d" % int(ProgressStore.progress.get("heads", 0))
	list.clear()
	for it in shop.list_items(tab):
		var owned: bool = shop.is_unlocked(tab, str(it.get("key"))) if tab != "i" else false
		list.add_item("%s %s — %d💀%s" % [it.get("icon","•"), it.get("name"), it.get("cost"), " ✓" if owned else ""])
		list.set_item_metadata(list.item_count - 1, it)
	status.text = "Shop [%s] — spend heads, then continue" % tab

func _on_tab_w(): tab="w"; _refresh()
func _on_tab_s(): tab="s"; _refresh()
func _on_tab_m(): tab="m"; _refresh()
func _on_tab_i(): tab="i"; _refresh()

func _on_item(index: int) -> void:
	var it: Dictionary = list.get_item_metadata(index)
	if shop.buy(tab, str(it.get("key"))):
		status.text = "Bought %s!" % it.get("name")
	else:
		status.text = "Not enough heads."
	_refresh()

func _on_back() -> void:
	GameState.stage_index += 1
	if GameState.stage_index >= DataRegistry.stages.size():
		GameState.end_run(true)
	else:
		GameState.set_state(GameState.State.INTRO)
