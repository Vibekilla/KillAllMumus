extends Node2D
## Outfit-tinted Bobina stand-in (modular; replace with animated sprites later).

@export var outfit_key: String = "og"

func _ready() -> void:
	queue_redraw()

func set_outfit(key: String) -> void:
	outfit_key = key
	queue_redraw()

func _draw() -> void:
	var colors := {
		"og": [Color("ff5b8d"), Color("ffd6f2")],
		"honeybee": [Color("ffd23a"), Color("fff3b0")],
		"cabal": [Color("ff3b1a"), Color("ffcf5a")],
		"nanosuit": [Color("3ad84a"), Color("e8324a")],
		"maid": [Color("f4efe6"), Color("d23a44")],
	}
	var pair: Array = colors.get(outfit_key, colors["og"])
	var body: Color = pair[0]
	var accent: Color = pair[1]
	# body
	draw_circle(Vector2(0, 2), 11, body)
	# head
	draw_circle(Vector2(0, -10), 9, accent)
	# ears
	draw_circle(Vector2(-7, -16), 4, body)
	draw_circle(Vector2(7, -16), 4, body)
	# eyes
	draw_circle(Vector2(-3, -11), 1.6, Color(0.1, 0.05, 0.1))
	draw_circle(Vector2(3, -11), 1.6, Color(0.1, 0.05, 0.1))
