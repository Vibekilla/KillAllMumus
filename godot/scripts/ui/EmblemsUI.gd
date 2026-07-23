extends Control

@onready var list: ItemList = %List
@onready var status: Label = %Status

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(func(s):
		visible = (s == &"EMBLEMS")
		if visible: _refresh()
	)

func _refresh() -> void:
	list.clear()
	var got := 0
	for e in DataRegistry.emblems:
		var id := str(e.get("id",""))
		var has := ProgressStore.has_emblem(id)
		if has: got += 1
		var lock := "" if has else "🔒 "
		list.add_item("%s%s %s — %s" % [lock, e.get("icon","★"), e.get("name",id), e.get("desc","")])
	status.text = "Emblems %d / %d" % [got, DataRegistry.emblems.size()]

func _on_back(): GameState.return_to_title()
