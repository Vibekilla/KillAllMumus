extends Node
## Fixed 60 Hz simulation clock — matches HTML simStep / requestAnimationFrame game tick.
## Display can run at any refresh; gameplay advances only on whole sim frames.

signal sim_tick(dt: float)
signal sim_frame(frame: int)

const HZ := 60.0
const DT := 1.0 / HZ

var tick: int = 0
var accumulator: float = 0.0
var paused: bool = false
var max_catchup_frames: int = 4  # avoid spiral of death

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if paused:
		return
	# When GameState is PAUSED, don't advance sim (menus still draw)
	if typeof(GameState) != TYPE_NIL and GameState.get("state") != null:
		if GameState.state == GameState.State.PAUSED:
			return
	accumulator += delta
	var steps := 0
	while accumulator >= DT and steps < max_catchup_frames:
		accumulator -= DT
		tick += 1
		steps += 1
		sim_tick.emit(DT)
		sim_frame.emit(tick)
	# Drop leftover if overloaded
	if accumulator > DT * max_catchup_frames:
		accumulator = 0.0

func reset() -> void:
	tick = 0
	accumulator = 0.0

func set_paused(p: bool) -> void:
	paused = p
