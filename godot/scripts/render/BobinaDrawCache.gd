extends Node
## Phase 1 performance: bake full drawBobina into textures.
## Menus/outfit previews (scale≥2) and in-game (scale 1, face buckets).
## HTML still owns pixels — this only avoids re-running the drawer every frame.

const PAD := 48.0
const MAX_ENTRIES := 128
## Quantize tick so breath/bob anim steps without unique tex every frame
const TICK_BUCKET := 4
## Play: coarser buckets = fewer SubViewport bakes (full drawBobina is very expensive)
const TICK_BUCKET_PLAY := 8
## Title mini: 2 breath poses. Play face bins freeze tick (see cache_key).
const BREATH_BINS := 2
## In-game facing bins (full 360 body rotate inside drawBobina).
## 24 bins → ≤7.5° step; bodyCtr error ≤ ~2px so soap bubble stays centered on body.
const FACE_BINS := 24

var _vp: SubViewport
var _host: Node2D
var _ctx: RefCounted
var _bobina: RefCounted
var _ready_tex: Dictionary = {}  # key -> ImageTexture
var _order: Array = []  # LRU keys
var _queue: Array = []  # {key, state, scale, size}
var _busy: bool = false
var _last_key: String = ""
var _last_play_tex: Texture2D = null
var bake_count: int = 0
var bake_usec_total: int = 0
## outfit|foN|eEXPR -> { "f-1.571": Texture2D } — O(bins) nearest, not O(bins×cache)
var _face_index: Dictionary = {}

func get_last_play_texture() -> Texture2D:
	return _last_play_tex

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
	var tb: int
	if scale >= 2.0:
		tb = int(floor(float(tick) / float(TICK_BUCKET)))
	elif extra.begins_with("f"):
		# Play face-bin: tick in the key made 24×2 new textures every 8 frames and
		# get_image() thrash. Full drawBobina pixels stay; breath is frozen in the bake.
		tb = 0
	else:
		tb = int(floor(float(tick) / float(TICK_BUCKET_PLAY))) % BREATH_BINS
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

## Playfield Bobina — HTML drawBobina rotates whole body by face (travel heading).
## We bake FACE_BINS orientations of drawBobina (true rotation in the drawer), then
## pick the nearest bin each frame. That is 1:1 art/orientation without live re-draw.
func get_play_texture(st: Dictionary) -> Texture2D:
	_ensure_viewport()
	var outfit := str(st.get("outfit", "og"))
	var face := _face_bucket(float(st.get("face", -PI / 2.0)))
	var focus := 1 if bool(st.get("focus", false)) else 0
	# Face bins are tick-stable (tb=0). Passing sim tick here used to mint a new
	# key every TICK_BUCKET_PLAY frames and GPU-readback forever.
	var expr = st.get("expr", null)
	var expr_key := str(expr) if expr != null and str(expr) != "" else "null"
	var extra := "f%.3f|fo%d|e%s" % [face, focus, expr_key]
	var key := cache_key(outfit, expr if expr_key != "null" else null, 0, 0, 1.0, extra)
	if _ready_tex.has(key):
		_touch(key)
		_last_play_tex = _ready_tex[key]
		return _ready_tex[key]
	# Nearest *face* bin already baked for this outfit (not a random frozen pose)
	var fallback: Texture2D = _nearest_face_tex(outfit, face, focus, expr_key)
	if fallback == null and _last_play_tex != null:
		fallback = _last_play_tex
	# Cap the bake queue — spinning the stick used to enqueue all 24 bins at once
	if fallback != null and _queue.size() >= 8:
		_last_play_tex = fallback
		return fallback
	var bake := st.duplicate(true)
	bake["face"] = face
	bake["tick"] = 0
	bake["iframe"] = 0
	bake["x"] = 0
	bake["y"] = 0
	bake["bombFx"] = 0
	bake["dash"] = 0
	if expr_key != "null":
		bake["expr"] = expr
	else:
		bake.erase("expr")
	_get_or_enqueue(key, outfit, expr if expr_key != "null" else null, 0, 1.0, bake)
	if fallback != null:
		_last_play_tex = fallback
	return fallback

func _play_face_key(outfit: String, face: float, focus: int, expr_key: String, tick: int = 0) -> String:
	var extra := "f%.3f|fo%d|e%s" % [face, focus, expr_key]
	return cache_key(outfit, null if expr_key == "null" else expr_key, 0, tick, 1.0, extra)

func _nearest_face_tex(outfit: String, want_face: float, focus: int, expr_key: String) -> Texture2D:
	## Pick closest prebaked face bin (HTML face is continuous; we sample FACE_BINS).
	var idx_key := "%s|fo%d|e%s" % [outfit, focus, expr_key]
	var bucket: Dictionary = _face_index.get(idx_key, {})
	if bucket.is_empty():
		return null
	var want := "f%.3f" % want_face
	if bucket.has(want):
		return bucket[want]
	var best: Texture2D = null
	var best_d := 999.0
	for fk in bucket.keys():
		var f := float(str(fk).substr(1))
		var d := absf(wrapf(f - want_face, -PI, PI))
		if d < best_d:
			best_d = d
			best = bucket[fk]
	return best

func _index_play(key: String, tex: Texture2D) -> void:
	var parts := key.split("|")
	if parts.size() < 8:
		return
	if not str(parts[5]).begins_with("f"):
		return
	var idx_key := "%s|%s|%s" % [parts[0], parts[6], parts[7]]
	if not _face_index.has(idx_key):
		_face_index[idx_key] = {}
	_face_index[idx_key][parts[5]] = tex

func _unindex_play(key: String) -> void:
	var parts := key.split("|")
	if parts.size() < 8:
		return
	if not str(parts[5]).begins_with("f"):
		return
	var idx_key := "%s|%s|%s" % [parts[0], parts[6], parts[7]]
	if _face_index.has(idx_key):
		_face_index[idx_key].erase(parts[5])

func prewarm_play_outfit(outfit: String, focus_both: bool = true) -> void:
	## Call on run/stage start — bakes all face bins so play can rotate 1:1 without hitching.
	_ensure_viewport()
	var focuses := [0, 1] if focus_both else [0]
	for fo in focuses:
		for i in range(FACE_BINS):
			var face := _face_bucket(-PI + float(i) * TAU / float(FACE_BINS))
			var key := _play_face_key(outfit, face, fo, "null", 0)
			if _ready_tex.has(key):
				continue
			var st := {
				"outfit": outfit, "face": face, "aim": face, "focus": fo == 1,
				"tick": 0, "x": 0, "y": 0, "vx": 0, "vy": 0,
				"iframe": 0, "dash": 0, "bombFx": 0, "lean": 0,
			}
			_get_or_enqueue(key, outfit, null, 0, 1.0, st)

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
	var expr = st.get("expr", null)
	var expr_key := str(expr) if expr != null and str(expr) != "" else "null"
	var extra := "f%.3f|fo%d|e%s" % [face, focus, expr_key]
	return _ready_tex.has(cache_key(outfit, expr if expr_key != "null" else null, 0, 0, 1.0, extra))

func clear_cache() -> void:
	## Dual playtest: drop bakes when forcing expr/outfit matrix
	_ready_tex.clear()
	_order.clear()
	_queue.clear()
	_face_index.clear()
	_last_play_tex = null

func _touch(key: String) -> void:
	var i := _order.find(key)
	if i >= 0:
		_order.remove_at(i)
	_order.append(key)

func _evict_if_needed() -> void:
	while _ready_tex.size() > MAX_ENTRIES and _order.size():
		var old: String = str(_order.pop_front())
		_ready_tex.erase(old)
		_unindex_play(old)

func _process(_d: float) -> void:
	if _busy or _queue.is_empty():
		return
	# Drain 1 bake/frame always (prewarm + miss). PLAY uses face-bin blit so bakes
	# must finish; SubViewport get_image is amortized, not every display frame.
	_busy = true
	_run_batch()

func _run_batch() -> void:
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
	var t0 := Time.get_ticks_usec()
	var img: Image = vtex.get_image()
	bake_usec_total += Time.get_ticks_usec() - t0
	bake_count += 1
	if img == null or img.is_empty():
		return
	var itex := ImageTexture.create_from_image(img)
	_ready_tex[key] = itex
	_index_play(key, itex)
	_touch(key)
	_evict_if_needed()
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
