extends Node
## Phase 1.3: bake full drawStageBg (+ motifs + drawStageBgFx) into a PF-sized texture.
## Re-bake on stage change / tick bucket / boss-intensity bucket.
## WorldDraw blits the texture every frame — entities stay 60 Hz; bg amortizes to ~15–20 Hz.

const TICK_BUCKET := 3
const MAX_ENTRIES := 24

var _vp: SubViewport
var _host: Node2D
var _ctx: RefCounted
var _drawer: RefCounted
var _ready_tex: Dictionary = {}  # key -> ImageTexture
var _order: Array = []
var _queue: Array = []  # {key, tick, stage, bi}
var _busy: bool = false
var _last_blit_key: String = ""
var _last_blit_tex: Texture2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_ensure_viewport()

func _ensure_viewport() -> void:
	if _vp != null:
		return
	_vp = SubViewport.new()
	_vp.name = "StageBgBakeVP"
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.size = Vector2i(512, 516)
	_vp.handle_input_locally = false
	add_child(_vp)
	_host = Node2D.new()
	_host.name = "BakeHost"
	_host.set_script(load("res://scripts/render/StageBgBakeHost.gd"))
	_vp.add_child(_host)
	_ctx = load("res://scripts/render/CanvasCompat.gd").new()
	_ctx.bind(_host)
	_drawer = load("res://scripts/render/drawers/drawStageBg.gd").new()
	_drawer.setup(_ctx)
	# Stable seeds for cache lifetime (HTML re-rolls only on stage construct)
	if "bg_seed" in _drawer:
		_drawer.bg_seed = 1.7
	if "bg_hue_seed" in _drawer:
		_drawer.bg_hue_seed = 12.0
	if "bg_petals" in _drawer:
		_drawer.bg_petals = 5
	if _host.has_method("configure"):
		_host.configure(_ctx, _drawer)

func _bi_bucket() -> int:
	## Match drawStageBgFx boss intensity — quantize so we re-bake on fight intensity shifts.
	var bi := 0.5
	var tree := get_tree()
	if tree == null:
		return int(floor(bi * 4.0))
	var bosses: Array = tree.get_nodes_in_group("bosses")
	for boss in bosses:
		if not is_instance_valid(boss) or bool(boss.get("dead")):
			continue
		var intro_v = boss.get("intro")
		if intro_v != null and float(intro_v) > 0.0:
			continue
		var rage := 0.8
		var st2 = boss.get("special_t")
		if st2 != null and float(st2) > 0.0:
			rage += 0.4
		var mhp = boss.get("max_hp")
		var hp = boss.get("hp")
		if mhp == null:
			mhp = boss.get("maxhp")
		if mhp != null and hp != null and float(mhp) > 0.0:
			rage += (1.0 - float(hp) / float(mhp)) * 0.35
		bi = minf(1.4, rage)
		break
	return int(floor(bi * 4.0))

func cache_key(stage: int, tick: int, bi_b: int) -> String:
	var tb := int(floor(float(tick) / float(TICK_BUCKET)))
	return "s%d|t%d|bi%d" % [stage, tb, bi_b]

func get_texture(tick: int) -> Texture2D:
	_ensure_viewport()
	var stage := int(GameState.stage_index) if GameState else 0
	var bi_b := _bi_bucket()
	var key := cache_key(stage, tick, bi_b)
	if _ready_tex.has(key):
		_touch(key)
		_last_blit_key = key
		_last_blit_tex = _ready_tex[key]
		return _ready_tex[key]
	# Stale same-stage texture while new bucket bakes (keeps bg continuous)
	var prefix := "s%d|" % stage
	var fallback: Texture2D = null
	if _last_blit_tex != null and _last_blit_key.begins_with(prefix):
		fallback = _last_blit_tex
	else:
		for k in _ready_tex.keys():
			if str(k).begins_with(prefix):
				fallback = _ready_tex[k]
				_touch(str(k))
				break
	_enqueue(key, tick, stage, bi_b)
	return fallback

func _enqueue(key: String, tick: int, stage: int, bi_b: int) -> void:
	for q in _queue:
		if str(q.get("key", "")) == key:
			return
	_queue.append({"key": key, "tick": tick, "stage": stage, "bi": bi_b})

func _touch(key: String) -> void:
	var i := _order.find(key)
	if i >= 0:
		_order.remove_at(i)
	_order.append(key)

func _evict_if_needed() -> void:
	while _ready_tex.size() > MAX_ENTRIES and _order.size():
		var old: String = str(_order.pop_front())
		_ready_tex.erase(old)

func _process(_d: float) -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	_run_one()

func _run_one() -> void:
	if _queue.is_empty():
		_busy = false
		return
	var job: Dictionary = _queue.pop_front()
	await _bake(job)
	_busy = false

func _bake(job: Dictionary) -> void:
	var key: String = str(job.get("key", ""))
	if key == "" or _ready_tex.has(key):
		return
	var tick: int = int(job.get("tick", 0))
	var pf: Rect2 = Config.playfield() if Config else Rect2(48, 14, 512, 516)
	var dim := Vector2i(int(ceil(pf.size.x)), int(ceil(pf.size.y)))
	if dim.x < 8 or dim.y < 8:
		return
	_vp.size = dim
	# Temporarily set stage for drawer match (drawer reads GameState.stage_index)
	if _host.has_method("set_bake"):
		_host.set_bake(tick, pf)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var vtex: ViewportTexture = _vp.get_texture()
	if vtex == null:
		_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var img: Image = vtex.get_image()
	if img == null or img.is_empty():
		_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var itex := ImageTexture.create_from_image(img)
	_ready_tex[key] = itex
	_touch(key)
	_evict_if_needed()
	_last_blit_key = key
	_last_blit_tex = itex
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
