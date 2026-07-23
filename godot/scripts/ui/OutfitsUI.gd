extends Control

@onready var list: ItemList = %List
@onready var status: Label = %Status

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(func(s):
		visible = (s == &"OUTFITS")
		if visible: _refresh()
	)

func _refresh() -> void:
	list.clear()
	var i := 0
	for o in DataRegistry.outfits:
		var key := str(o.get("key"))
		var unl := ProgressStore.outfit_unlocked(key)
		var eq := key == GameState.selected_outfit
		var mark := "✓" if eq else ("·" if unl else "🔒")
		list.add_item("%s %s %s" % [mark, o.get("emoji","👗"), o.get("name", key)])
		list.set_item_metadata(i, key)
		i += 1
	status.text = "Equipped: %s" % GameState.selected_outfit

func _on_item(index: int) -> void:
	var key := str(list.get_item_metadata(index))
	if ProgressStore.outfit_unlocked(key):
		GameState.selected_outfit = key
		ProgressStore.progress["outfit"] = key
		ProgressStore.queue_save()
		_refresh()

func _on_back(): GameState.return_to_title()
