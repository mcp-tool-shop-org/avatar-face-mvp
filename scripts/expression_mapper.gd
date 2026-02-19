## Maps driver output names to VRM blendshape names with smoothing and clamping.
## This is core infrastructure — treat it as such.
class_name ExpressionMapper
extends RefCounted

## VRM 1.0 standard expression names
const VRM_VISEMES := {
	"aa": "viseme_aa",
	"ih": "viseme_ih",
	"ou": "viseme_ou",
	"ee": "viseme_ee",
	"oh": "viseme_oh",
}

const VRM_EXPRESSIONS := {
	"blink_left": "blinkLeft",
	"blink_right": "blinkRight",
	"happy": "happy",
	"sad": "sad",
	"angry": "angry",
	"surprised": "surprised",
	"neutral": "neutral",
}

## Smoothing parameters (seconds)
var attack_time := 0.06  # How fast weights rise
var release_time := 0.12  # How fast weights fall

## Current smoothed weights keyed by VRM expression name
var _current_weights: Dictionary = {}

## Get the full mapping table (driver name -> VRM name)
func get_full_map() -> Dictionary:
	var merged := {}
	merged.merge(VRM_VISEMES)
	merged.merge(VRM_EXPRESSIONS)
	return merged


## Map a dictionary of driver weights to VRM blendshape weights with smoothing.
## driver_weights: { "aa": 0.8, "ih": 0.2, ... }
## delta: frame delta time
## Returns: { "viseme_aa": 0.75, "viseme_ih": 0.18, ... } (smoothed VRM names)
func map_and_smooth(driver_weights: Dictionary, delta: float) -> Dictionary:
	var full_map := get_full_map()
	var result: Dictionary = {}

	for driver_name in full_map:
		var vrm_name: String = full_map[driver_name]
		var target: float = driver_weights.get(driver_name, 0.0)
		target = clampf(target, 0.0, 1.0)

		var current: float = _current_weights.get(vrm_name, 0.0)

		# Exponential smoothing with separate attack/release
		var speed: float
		if target > current:
			speed = 1.0 - exp(-delta / maxf(attack_time, 0.001))
		else:
			speed = 1.0 - exp(-delta / maxf(release_time, 0.001))

		var smoothed := lerpf(current, target, speed)
		# Kill tiny values to avoid perpetual micro-animations
		if smoothed < 0.005:
			smoothed = 0.0

		_current_weights[vrm_name] = smoothed
		result[vrm_name] = smoothed

	return result


## Reset all weights to zero (e.g., when switching avatars)
func reset():
	_current_weights.clear()
