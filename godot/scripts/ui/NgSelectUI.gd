extends Control

@onready var status: Label = %Status
@onready var list: ItemList = %List

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(func(s):
		visible = (s == &"NG_SELECT")
		if visible: _refresh()
	)

func _refresh() -> void:
	list.clear()
	var max_n := ProgressStore.ng_unlocked
	for i in range(0, max_n + 1):
		var mark := "▶" if i == GameState.ng_plus else "·"
		list.add_item("%s NG+ %s" % [mark, ("OFF" if i == 0 else str(i))])
	status.text = "Unlocked through Lv%d · selected %s" % [max_n, ("OFF" if GameState.ng_plus==0 else str(GameState.ng_plus))]

func _on_item(index: int) -> void:
	GameState.ng_plus = index
	ProgressStore.progress["ngPlus"] = index
	ProgressStore.queue_save()
	_refresh()

func _on_back(): GameState.return_to_title()
