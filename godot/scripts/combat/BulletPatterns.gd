extends RefCounted
## HTML parity: eb / ring / fanAt / heavyShell (speeds in px/frame → *60 for Godot).

const FRAME := 60.0
const TEAM_ENEMY := 1

static func frame_spd(spd: float) -> float:
	return spd * FRAME * _spd_mul()

static func _spd_mul() -> float:
	## HTML loadStage: SPD = (hardMode?1:0.8) * (1 + stageIdx*0.13) * threatMul()
	## hardMode = difficulty>=1; threatMul = (hell?1.28:1)*(1+ng*0.16)
	var base := 1.0 if GameState.hard_mode else 0.8
	var stage_mul := 1.0 + float(GameState.stage_index) * 0.13
	var threat := 1.0
	if GameState:
		if GameState.has_method("threat_mul"):
			threat = float(GameState.threat_mul())
		else:
			threat = (1.28 if GameState.hell_mode else 1.0) * (1.0 + float(GameState.ng_plus) * 0.16)
	return base * stage_mul * threat

static func col(c) -> Color:
	if c is Color:
		return c
	var s := str(c).strip_edges()
	if s.begins_with("#"):
		return Color.html(s)
	return Color(1.0, 0.4, 0.65)

static func eb(pool: Node, x: float, y: float, ang: float, spd: float, r: float = 6.0, color = "#ff6ec7", hp: float = 0.0) -> void:
	if pool == null:
		return
	var v := Vector2.from_angle(ang) * frame_spd(spd)
	var b = pool.spawn(Vector2(x, y), v, 1.0, col(color), TEAM_ENEMY)
	if b and b.has_method("set_props"):
		b.set_props({"radius": r, "hp": hp, "shell": false})

static func ring(pool: Node, x: float, y: float, n: int, spd: float, r: float, color, off: float = 0.0) -> void:
	for i in n:
		eb(pool, x, y, off + float(i) / float(n) * TAU, spd, r, color)

static func fan_at(pool: Node, x: float, y: float, tx: float, ty: float, n: int, arc: float, spd: float, r: float, color) -> void:
	var base := atan2(ty - y, tx - x)
	var den := maxf(1.0, float(n - 1))
	for i in n:
		var a := base + (float(i) - float(n - 1) * 0.5) * (arc / den)
		eb(pool, x, y, a, spd, r, color)

static func heavy_shell(pool: Node, x: float, y: float, tx: float, ty: float, spd: float) -> void:
	if pool == null:
		return
	var a := atan2(ty - y, tx - x)
	var v := Vector2.from_angle(a) * frame_spd(spd)
	var b = pool.spawn(Vector2(x, y), v, 1.0, col("#ffd27a"), TEAM_ENEMY)
	if b and b.has_method("set_props"):
		b.set_props({"radius": 12.0, "hp": 4.0, "shell": true})
