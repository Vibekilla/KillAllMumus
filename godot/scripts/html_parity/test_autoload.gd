extends SceneTree
func _init():
	print("DataRegistry=", DataRegistry)
	print("outfits=", DataRegistry.outfits.size())
	var t = load("res://scripts/render/drawers/drawTitle.gd")
	print("title script=", t)
	if t:
		var inst = t.new()
		print("inst=", inst)
	quit()
