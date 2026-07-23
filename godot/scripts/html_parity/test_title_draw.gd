extends SceneTree
func _init():
	print("[TEST] title draw smoke")
	var node = Node2D.new()
	root.add_child(node)
	var CanvasCompat = load("res://scripts/render/CanvasCompat.gd")
	var PortedDraw = load("res://scripts/render/PortedDraw.gd")
	var ctx = CanvasCompat.new()
	ctx.bind(node)
	var pd = PortedDraw.new()
	pd.setup(ctx)
	pd.set_tick(100)
	ctx.begin_frame()
	pd.draw_title({
		"outfit": "og",
		"tick": 100,
		"title_idle_t": 0,
		"is_touch": false,
		"difficulty": 1,
		"ng_plus": 0,
		"ng_unlocked": 1,
	})
	var btns = pd.get_title_btns()
	print("[TEST] title buttons=", btns.size())
	var ids = []
	for b in btns:
		ids.append(str(b.get("id", "")))
	print("[TEST] ids=", ",".join(ids))
	# maid dance path
	ctx.begin_frame()
	pd.draw_title({
		"outfit": "og", "tick": 200, "title_idle_t": 2000,
		"is_touch": false, "difficulty": 0, "ng_plus": 0, "ng_unlocked": 0,
	})
	print("[TEST] maid dance path ok")
	print("[TEST] TITLE OK")
	quit()
