extends Area2D
## Modular boss — pattern table driven by stage boss id.

signal defeated(boss_id: String)

var boss_id: String = ""
var max_hp: float = 100.0
var hp: float = 100.0
var bullet_pool: Node
var pattern_t: float = 0.0
var phase: int = 0

func setup(pool: Node, pos: Vector2, id: String, hp_val: float) -> void:
	bullet_pool = pool
	boss_id = id
	max_hp = hp_val
	hp = hp_val
	global_position = pos
	add_to_group("enemies")
	add_to_group("bosses")

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	pattern_t += delta
	# Bob left-right
	var pf: Rect2 = Config.PLAYFIELD
	position.x = pf.get_center().x + sin(pattern_t * 0.8) * (pf.size.x * 0.28)
	position.y = pf.position.y + 90 + sin(pattern_t * 0.4) * 12.0
	_pattern(delta)
	queue_redraw()

func _pattern(_delta: float) -> void:
	if bullet_pool == null:
		return
	if int(pattern_t * 10) % 8 != 0:
		return
	var n := 8 + phase * 4
	for i in n:
		var a := pattern_t + TAU * i / float(n)
		var spd := 90.0 * GameState.threat_mul()
		bullet_pool.spawn(global_position, Vector2.from_angle(a) * spd, 1.0, Color(1.0, 0.3, 0.55), 1)
	if hp < max_hp * 0.5:
		phase = 1
	if hp < max_hp * 0.25:
		phase = 2

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		ProgressStore.estats_add("bosses", 1)
		GameState.add_score(int(5000 * GameState.score_mul()))
		defeated.emit(boss_id)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 28, Color(0.85, 0.2, 0.4))
	draw_circle(Vector2.ZERO, 18, Color(0.2, 0.05, 0.1))
	# HP bar
	var w := 60.0
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-w/2, -40, w, 5), Color(0.2, 0.1, 0.15))
	draw_rect(Rect2(-w/2, -40, w * ratio, 5), Color(1.0, 0.35, 0.55))
