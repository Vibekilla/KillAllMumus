extends Node
## Phase 1 performance: bake full drawBobina into textures for menu / outfit previews.
## HTML still owns pixels; this only avoids re-running the expensive drawer every frame.
## WorldDraw in-game path can adopt the same cache later (Phase 1.2).

const PAD := 48.0
const MAX_ENTRIES := 64
## Quantize tick so breath/bob anim steps without unique tex every frame
const TICK_BUCKET := 4

var _vp: SubViewport
var _host: Node2D
var _ctx: RefCounted
var _bobina: RefCounted
var _ready_tex: Dictionary = {}  # key -> ImageTexture
var _order: Array = []  # LRU keys
var _queue: Array = []  # {key, state, scale, size}
var _busy: bool = false
var _last_key: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_ensure_viewport()

func _ensure_viewport() -> void:
	if _vp != null:
		return
	_vp = SubViewport.new()
	_vp.name = "BobinaBakeVP"
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.size = Vector2i(256, 256)
	_vp.handle_input_locally = false
	add_child(_vp)
	_host = Node2D.new()
	_host.name = "BakeHost"
	_host.set_script(load("res://scripts/render/BobinaBakeHost.gd"))
	_vp.add_child(_host)
	_ctx = load("res://scripts/render/CanvasCompat.gd").new()
	_ctx.bind(_host)
	_bobina = load("res://scripts/render/drawers/drawBobina.gd").new()
	_bobina.setup(_ctx)
	if _host.has_method("configure"):
		_host.configure(_ctx, _bobina)

func cache_key(outfit: String, expr, pose: int, tick: int, scale: float) -> String:
	var e := str(expr) if expr != null else "null"
	var tb := int(floor(float(tick) / float(TICK_BUCKET)))
	var sc := snappedf(scale, 0.1)
	return "%s|%s|%d|%d|%.1f" % [outfit, e, pose, tb, sc]

func get_texture(outfit: String, expr, pose: int, tick: int, scale: float, state: Dictionary = {}) -> Texture2D:
	_ensure_viewport()
	var key := cache_key(outfit, expr, pose, tick, scale)
	if _ready_tex.has(key):
		_touch(key)
		return _ready_tex[key]
	# Enqueue bake (one per process tick)
	var found := false
	for q in _queue:
		if str(q.get("key", "")) == key:
			found = true
			break
	if not found:
		var st := state.duplicate(true)
		st["outfit"] = outfit
		st["tick"] = tick
		if expr != null:
			st["expr"] = expr
		_queue.append({
			"key": key,
			"state": st,
			"scale": scale,
			"pose": pose,
		})
	return null

func has_texture(outfit: String, expr, pose: int, tick: int, scale: float) -> bool:
	return _ready_tex.has(cache_key(outfit, expr, pose, tick, scale))

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
	_run_next()

func _run_next() -> void:
	var job: Dictionary = _queue.pop_front()
	await _bake(job)
	_busy = false

func _bake(job: Dictionary) -> void:
	var key: String = str(job.get("key", ""))
	if key == "" or _ready_tex.has(key):
		return
	var scale: float = float(job.get("scale", 1.0))
	var st: Dictionary = job.get("state", {})
	# Character local bounds roughly ±40; pad for props
	var half := int(ceil(PAD * maxf(1.0, scale)))
	var dim := clampi(half * 2, 96, 512)
	_vp.size = Vector2i(dim, dim)
	if _host.has_method("set_bake"):
		_host.set_bake(st, scale, float(dim) * 0.5)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# Need a frame for SubViewport to rasterize
	await RenderingServer.frame_post_draw
	var vtex: ViewportTexture = _vp.get_texture()
	if vtex == null:
		return
	var img: Image = vtex.get_image()
	if img == null or img.is_empty():
		return
	var itex := ImageTexture.create_from_image(img)
	_ready_tex[key] = itex
	_touch(key)
	_evict_if_needed()
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
