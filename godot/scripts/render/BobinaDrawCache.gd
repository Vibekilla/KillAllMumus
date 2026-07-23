extends Node
## Phase 1 performance: bake full drawBobina into textures.
## Menus/outfit previews (scale≥2) and in-game (scale 1, face buckets).
## HTML still owns pixels — this only avoids re-running the drawer every frame.

const PAD := 48.0
const MAX_ENTRIES := 96
## Quantize tick so breath/bob anim steps without unique tex every frame
const TICK_BUCKET := 4
const TICK_BUCKET_PLAY := 3
## In-game facing bins (full 360 body rotate inside drawBobina)
const FACE_BINS := 16

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

func cache_key(outfit: String, expr, pose: int, tick: int, scale: float, extra: String = "") -> String:
	var e := str(expr) if expr != null else "null"
	var tb := int(floor(float(tick) / float(TICK_BUCKET if scale >= 2.0 else TICK_BUCKET_PLAY)))
	var sc := snappedf(scale, 0.1)
	return "%s|%s|%d|%d|%.1f|%s" % [outfit, e, pose, tb, sc, extra]

func _face_bucket(face: float) -> float:
	var step := TAU / float(FACE_BINS)
	return roundf(face / step) * step

func get_texture(outfit: String, expr, pose: int, tick: int, scale: float, state: Dictionary = {}) -> Texture2D:
	_ensure_viewport()
	# Pose 5 coffeeHold sip position must affect key (not only tick bucket)
	var extra := ""
	if state is Dictionary and state.has("hold"):
		var h = state["hold"]
		if h is Dictionary:
			extra = "h%.1f_%.1f" % [float(h.get("x", 0)), float(h.get("y", 0))]
	var key := cache_key(outfit, expr, pose, tick, scale, extra)
	return _get_or_enqueue(key, outfit, expr, tick, scale, state)

## Playfield Bobina: quantize facing + focus; iframe/alpha applied by caller at blit.
func get_play_texture(st: Dictionary) -> Texture2D:
	_ensure_viewport()
	var outfit := str(st.get("outfit", "og"))
	var face := _face_bucket(float(st.get("face", -PI / 2.0)))
	var focus := 1 if bool(st.get("focus", false)) else 0
	var tick := int(st.get("tick", 0))
	var extra := "f%.3f|fo%d" % [face, focus]
	var key := cache_key(outfit, null, 0, tick, 1.0, extra)
	if _ready_tex.has(key):
		_touch(key)
		return _ready_tex[key]
	# Stale-but-close frame: same outfit/face/focus, any tick bucket (avoids live drawBobina)
	var prefix := "%s|null|0|" % outfit
	var suffix := "|1.0|%s" % extra
	var fallback: Texture2D = null
	for k in _ready_tex.keys():
		var ks := str(k)
		if ks.begins_with(prefix) and ks.ends_with(suffix):
			fallback = _ready_tex[k]
			_touch(ks)
			break
	var bake := st.duplicate(true)
	bake["face"] = face
	bake["iframe"] = 0  # flash applied at blit
	bake["x"] = 0
	bake["y"] = 0
	bake["bombFx"] = 0
	bake["dash"] = 0
	_get_or_enqueue(key, outfit, null, tick, 1.0, bake)
	return fallback  # null only until first bake for this facing lands

func _get_or_enqueue(key: String, outfit: String, expr, tick: int, scale: float, state: Dictionary) -> Texture2D:
	if _ready_tex.has(key):
		_touch(key)
		return _ready_tex[key]
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
		# Prefer play bakes (scale 1) — insert front so combat stays smooth
		var job := {"key": key, "state": st, "scale": scale, "pose": 0}
		if scale < 2.0:
			_queue.push_front(job)
		else:
			_queue.append(job)
	return null

func has_texture(outfit: String, expr, pose: int, tick: int, scale: float) -> bool:
	return _ready_tex.has(cache_key(outfit, expr, pose, tick, scale))

func has_play_texture(st: Dictionary) -> bool:
	var outfit := str(st.get("outfit", "og"))
	var face := _face_bucket(float(st.get("face", -PI / 2.0)))
	var focus := 1 if bool(st.get("focus", false)) else 0
	var tick := int(st.get("tick", 0))
	var extra := "f%.3f|fo%d" % [face, focus]
	return _ready_tex.has(cache_key(outfit, null, 0, tick, 1.0, extra))

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
	# Drain up to 2 play-priority jobs per frame when queue is deep
	_run_batch()

func _run_batch() -> void:
	var n := mini(2, _queue.size()) if _queue.size() > 3 else 1
	for _i in range(n):
		if _queue.is_empty():
			break
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
