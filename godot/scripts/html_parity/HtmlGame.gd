extends Control
## Full-canvas host for the HTML game port.
## Layout matches applyLayout(false): 960×540, PF={48,14,512,516}, PANEL right rail.
##
## While individual draw* modules are still being line-ported from
## tools/port/extracted/functions/, this host:
##  1. Uses the complete combat systems already ported
##  2. Draws through CanvasCompat with PortedDraw
##  3. Plays HTML-identical sfx() via AudioBus
##
## Live production must use public/index.html until every draw* is verified.
## See res://PARITY.md

const W := 960.0
const H := 540.0
const PF := Rect2(48, 14, 512, 516)

@onready var canvas: Node2D = $GameCanvas

var tick: int = 0
var screen_shake: float = 0.0
var assets: Node

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	assets = preload("res://scripts/html_parity/AssetBank.gd").new()
	add_child(assets)
	# Prefer starting at title via GameState
	if GameState.state == GameState.State.TITLE:
		pass
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	if GameState.state == GameState.State.PLAY:
		tick += 1
	if canvas:
		canvas.queue_redraw()
	queue_redraw()

func _draw() -> void:
	# Outer frame / letterbox like the HTML page background
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.03, 0.08))
	# Playfield border (HTML: strokeRect pink)
	draw_rect(PF.grow(1.0), Color(1.0, 0.55, 0.78, 0.5), false, 2.0)
