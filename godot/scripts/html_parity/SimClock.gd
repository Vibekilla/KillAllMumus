extends Node
## Fixed-timestep simulation clock — HTML `simStep` / 60 Hz parity.
##
## Architecture (do not replace with variable-delta combat):
##   1. Accumulate real `delta`; advance only whole `SIM_DT` steps.
##   2. Combat / AI / bullets / stage / power-ups → fixed step only.
##   3. Bobina breath/blink/sway + most FX → `sim_frame` (`% N`) or `sim_time` (sines).
##   4. Rendering stays free-running at display rate; use `alpha` if you interpolate.
##
## Never drive combat from wall-clock `Time.get_ticks_*` or pure variable `delta`.
##
## Compat: `tick` is an alias for `sim_frame` (drawers, dual QA, existing call sites).

signal sim_tick(dt: float)
## Emitted after each fixed step with the new frame index (was also named sim_frame signal).
signal frame_advanced(frame: int)

const HZ := 60.0
const SIM_DT := 1.0 / HZ
## Alias used across systems (same value as SIM_DT).
const DT := SIM_DT
## HTML-style “frames per second” scale (px/frame * FRAME ≈ px/sec at 60).
const FRAME := HZ

var _sim_frame: int = 0
var sim_time: float = 0.0
var accumulator: float = 0.0
## Fractional progress toward the next sim step in [0, 1) — render interp only.
var alpha: float = 0.0
var paused: bool = false
var max_catchup_frames: int = 4
## Last display-frame delta (not for simulation logic).
var display_delta: float = 0.0

## Integer HTML-equivalent frame index. Setting it keeps `sim_time` aligned.
var sim_frame: int:
	get:
		return _sim_frame
	set(v):
		_sim_frame = int(v)
		sim_time = float(_sim_frame) * SIM_DT

## Back-compat alias for HTML `tick` / dual QA (`tick % 230`, etc.).
var tick: int:
	get:
		return _sim_frame
	set(v):
		sim_frame = int(v)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Align Godot physics step with HTML sim when possible (Player/Enemy _physics_process).
	Engine.physics_ticks_per_second = int(HZ)

func _process(delta: float) -> void:
	display_delta = delta
	if paused:
		alpha = 0.0
		return
	# GameState.PAUSED freezes sim; menus still redraw from last sim_frame/sim_time.
	if typeof(GameState) != TYPE_NIL and GameState.get("state") != null:
		if GameState.state == GameState.State.PAUSED:
			alpha = 0.0
			return
	accumulator += delta
	var steps := 0
	while accumulator >= SIM_DT and steps < max_catchup_frames:
		accumulator -= SIM_DT
		_step()
		steps += 1
	# Spiral-of-death guard
	if accumulator > SIM_DT * float(max_catchup_frames):
		accumulator = 0.0
	alpha = clampf(accumulator / SIM_DT, 0.0, 1.0)

func _step() -> void:
	_sim_frame += 1
	sim_time = float(_sim_frame) * SIM_DT
	sim_tick.emit(SIM_DT)
	frame_advanced.emit(_sim_frame)

func reset() -> void:
	_sim_frame = 0
	sim_time = 0.0
	accumulator = 0.0
	alpha = 0.0

func set_paused(p: bool) -> void:
	paused = p

## HTML blink: `(tick % 230) < 7 && !squee` — call with squee check at site.
func blink_closed(period: int = 230, closed_frames: int = 7) -> bool:
	return (_sim_frame % period) < closed_frames

## Same window in seconds: `fmod(sim_time, 230/60) < 7/60`.
func blink_closed_time(period_frames: int = 230, closed_frames: int = 7) -> bool:
	var period_t := float(period_frames) * SIM_DT
	var closed_t := float(closed_frames) * SIM_DT
	return fmod(sim_time, period_t) < closed_t

func frames_to_time(frames: float) -> float:
	return float(frames) * SIM_DT

func time_to_frames(seconds: float) -> int:
	return int(floor(seconds * HZ + 1e-9))

## Prefer this over ad-hoc `delta * 60` when a display callback must scale to frames.
func delta_frames(delta: float) -> float:
	return delta * HZ
