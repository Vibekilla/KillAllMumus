extends Control

@onready var list: ItemList = %List
@onready var title: Label = %Title

var tab := "w"

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(func(s):
		visible = (s == &"ARSENAL")
		if visible: _refresh()
	)

func _refresh() -> void:
	list.clear()
	title.text = "🎒 ARSENAL — tab: %s" % tab
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var equipped: Array = ar.get(tab, [])
	match tab:
		"w":
			for k in DataRegistry.weapons.keys():
				var mark := "✓" if k in equipped else "·"
				list.add_item("%s %s %s" % [mark, DataRegistry.weapons[k].get("icon","•"), DataRegistry.weapons[k].get("name", k)])
		"s":
			for s in DataRegistry.specials:
				var k := str(s.get("key"))
				var mark := "✓" if k in equipped else "·"
				list.add_item("%s %s %s" % [mark, s.get("icon","★"), s.get("name", k)])
		"m":
			for m in DataRegistry.melee:
				var k := str(m.get("key"))
				var mark := "✓" if k in equipped else "·"
				list.add_item("%s %s %s" % [mark, m.get("icon","🗡"), m.get("name", k)])

func _on_tab_w(): tab="w"; _refresh()
func _on_tab_s(): tab="s"; _refresh()
func _on_tab_m(): tab="m"; _refresh()
func _on_back(): GameState.return_to_title()
