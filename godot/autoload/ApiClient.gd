extends Node
## HTTP client for killallmumus.com Express API (scores, auth, progress).

signal auth_changed(authenticated: bool)
signal scores_received(scores: Array)
signal progress_received(progress: Dictionary)

var authenticated: bool = false
var me: Dictionary = {}
var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)

func is_authenticated() -> bool:
	return authenticated

func _url(path: String) -> String:
	return Config.api_base_url.rstrip("/") + path

func refresh_me() -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result, code, _h, body):
		req.queue_free()
		if code != 200:
			authenticated = false
			me = {}
			auth_changed.emit(false)
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(data) == TYPE_DICTIONARY and data.get("authenticated", false):
			authenticated = true
			me = data
			auth_changed.emit(true)
			pull_progress()
		else:
			authenticated = false
			me = {}
			auth_changed.emit(false)
	)
	req.request(_url("/api/me"))

func pull_progress() -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result, code, _h, body):
		req.queue_free()
		if code != 200:
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if typeof(data) == TYPE_DICTIONARY and data.get("ok", false):
			var prog: Dictionary = data.get("progress", {})
			ProgressStore.merge_from_cloud(prog)
			progress_received.emit(prog)
	)
	req.request(_url("/api/progress"))

func put_progress(progress: Dictionary) -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r, _c, _h, _b):
		req.queue_free()
	)
	var payload := JSON.stringify({"progress": progress})
	req.request(
		_url("/api/progress"),
		["Content-Type: application/json"],
		HTTPClient.METHOD_PUT,
		payload
	)

func fetch_scores() -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result, code, _h, body):
		req.queue_free()
		if code != 200:
			scores_received.emit([])
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		# HTML accepts Array or {scores:[]}
		if typeof(data) == TYPE_ARRAY:
			scores_received.emit(data)
		elif typeof(data) == TYPE_DICTIONARY and data.get("scores") is Array:
			scores_received.emit(data["scores"])
		else:
			scores_received.emit([])
	)
	req.request(_url("/api/scores"))

func submit_score(payload: Dictionary) -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result, code, _h, body):
		req.queue_free()
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_DICTIONARY and data.get("scores") is Array:
				scores_received.emit(data["scores"])
			elif typeof(data) == TYPE_ARRAY:
				scores_received.emit(data)
	)
	req.request(
		_url("/api/scores"),
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)

func login_url() -> String:
	var handle := str(ProgressStore.progress.get("handle", ""))
	var q := ""
	if handle != "":
		q = "?claim_handle=" + handle.uri_encode()
	return _url("/auth/bobina" + q)

func open_login() -> void:
	# Web: navigate. Desktop: open browser.
	var url := login_url()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href='%s'" % url)
	else:
		OS.shell_open(url)
