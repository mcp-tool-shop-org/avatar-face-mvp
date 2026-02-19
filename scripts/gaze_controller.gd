## Eye gaze controller with micro-saccades.
## Drives eye bones (or blendshapes as fallback) for natural eye movement.
## Supports: gaze target tracking, micro-saccades, and smooth transitions.
class_name GazeController
extends RefCounted

## Gaze target modes
enum GazeMode { CAMERA, IDLE_WANDER, CURSOR }

## Saccade timing
var saccade_min_interval := 0.25  # seconds
var saccade_max_interval := 0.7
var saccade_amplitude := 1.2  # degrees

## Eye clamp (human range)
var max_yaw := 20.0  # degrees
var max_pitch := 12.0  # degrees

## Smooth speed
var eye_speed := 12.0  # lerp factor per second

## Current mode
var mode: int = GazeMode.CAMERA

## State
var _current_left := Vector3.ZERO  # euler radians
var _current_right := Vector3.ZERO
var _target_offset := Vector2.ZERO  # yaw, pitch offset in degrees
var _saccade_timer := 0.0
var _saccade_interval := 0.4
var _saccade_offset := Vector2.ZERO  # current saccade jitter
var _wander_target := Vector2.ZERO
var _wander_timer := 0.0
var _wander_interval := 2.0

var _rng := RandomNumberGenerator.new()
var _active := false

## Blendshape fallback names (ARKit-style eye look shapes)
var _use_blendshapes := false
var _blend_shape_weights: Dictionary = {}


func _init():
	_rng.randomize()
	_saccade_interval = _rng.randf_range(saccade_min_interval, saccade_max_interval)


## Set up — check if eye bones exist, otherwise prepare blendshape mode.
func setup(idle_controller: IdleController):
	_active = false
	_current_left = Vector3.ZERO
	_current_right = Vector3.ZERO
	_target_offset = Vector2.ZERO
	_saccade_offset = Vector2.ZERO

	if idle_controller.has_eye_bones():
		_use_blendshapes = false
		_active = true
	else:
		# Check if we can use blendshape-based eye control
		# (handled externally via get_blendshape_weights)
		_use_blendshapes = true
		_active = true

	_blend_shape_weights.clear()


func is_active() -> bool:
	return _active


## Call every frame. Returns true if eye bones were updated directly.
## If using blendshapes, call get_blendshape_weights() instead.
func update(delta: float, idle_controller: IdleController) -> bool:
	if not _active:
		return false

	# Update saccade jitter
	_saccade_timer += delta
	if _saccade_timer >= _saccade_interval:
		_saccade_timer = 0.0
		_saccade_interval = _rng.randf_range(saccade_min_interval, saccade_max_interval)
		# Quick saccade — new random offset
		_saccade_offset = Vector2(
			_rng.randf_range(-saccade_amplitude, saccade_amplitude),
			_rng.randf_range(-saccade_amplitude * 0.6, saccade_amplitude * 0.6)
		)

	# Compute gaze direction based on mode
	var gaze_yaw := 0.0
	var gaze_pitch := 0.0

	match mode:
		GazeMode.CAMERA:
			# Look slightly off-center (avoid dead stare) + saccades
			gaze_yaw = _saccade_offset.x
			gaze_pitch = _saccade_offset.y + 0.5  # slight upward bias

		GazeMode.IDLE_WANDER:
			# Slow random wander + saccades
			_wander_timer += delta
			if _wander_timer >= _wander_interval:
				_wander_timer = 0.0
				_wander_interval = _rng.randf_range(1.5, 4.0)
				_wander_target = Vector2(
					_rng.randf_range(-8.0, 8.0),
					_rng.randf_range(-4.0, 4.0)
				)
			gaze_yaw = _wander_target.x + _saccade_offset.x
			gaze_pitch = _wander_target.y + _saccade_offset.y

		GazeMode.CURSOR:
			# Placeholder — would need screen-space cursor position
			gaze_yaw = _saccade_offset.x
			gaze_pitch = _saccade_offset.y

	# Clamp
	gaze_yaw = clampf(gaze_yaw, -max_yaw, max_yaw)
	gaze_pitch = clampf(gaze_pitch, -max_pitch, max_pitch)

	# Convert to radians
	var target_yaw := deg_to_rad(gaze_yaw)
	var target_pitch := deg_to_rad(gaze_pitch)

	# Slight convergence (eyes angle slightly inward) — 0.5 degrees
	var convergence := deg_to_rad(0.5)

	var left_target := Vector3(target_pitch, target_yaw + convergence, 0.0)
	var right_target := Vector3(target_pitch, target_yaw - convergence, 0.0)

	# Smooth toward target
	var speed := eye_speed * delta
	_current_left = _current_left.lerp(left_target, minf(speed, 1.0))
	_current_right = _current_right.lerp(right_target, minf(speed, 1.0))

	if _use_blendshapes:
		_compute_blendshape_weights()
		return false
	else:
		# Apply to eye bones via idle controller
		idle_controller.apply_eye_rotation(_current_left, _current_right)
		return true


## Get blendshape weights for eye look (ARKit-style).
## Returns driver-name keyed weights that go through ExpressionMapper.
func get_blendshape_weights() -> Dictionary:
	return _blend_shape_weights


## Notify gaze controller of a large head saccade (triggers sympathetic eye movement).
func on_head_saccade():
	# Eyes often lead or follow head saccades — trigger a quick eye jump
	_saccade_timer = _saccade_interval  # force immediate saccade


func _compute_blendshape_weights():
	_blend_shape_weights.clear()
	# Convert euler to ARKit-style blendshape weights
	# Positive yaw = look right, negative = look left
	var yaw_deg := rad_to_deg(_current_left.y)  # Use left eye as reference
	var pitch_deg := rad_to_deg(_current_left.x)

	if yaw_deg > 0.5:
		var w := clampf(yaw_deg / max_yaw, 0.0, 1.0)
		_blend_shape_weights["eyeLookOut_L"] = w
		_blend_shape_weights["eyeLookIn_R"] = w
	elif yaw_deg < -0.5:
		var w := clampf(-yaw_deg / max_yaw, 0.0, 1.0)
		_blend_shape_weights["eyeLookIn_L"] = w
		_blend_shape_weights["eyeLookOut_R"] = w

	if pitch_deg > 0.3:
		var w := clampf(pitch_deg / max_pitch, 0.0, 1.0)
		_blend_shape_weights["eyeLookDown_L"] = w
		_blend_shape_weights["eyeLookDown_R"] = w
	elif pitch_deg < -0.3:
		var w := clampf(-pitch_deg / max_pitch, 0.0, 1.0)
		_blend_shape_weights["eyeLookUp_L"] = w
		_blend_shape_weights["eyeLookUp_R"] = w
