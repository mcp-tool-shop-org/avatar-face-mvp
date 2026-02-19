## Maps driver output names to VRM blendshape names with smoothing and clamping.
## This is core infrastructure — treat it as such.
## Loads mapping from config/mapping.json. Falls back to hardcoded defaults.
class_name ExpressionMapper
extends RefCounted

## Hardcoded fallbacks (used when config is missing)
const DEFAULT_VISEMES := {
	"aa": "viseme_aa",
	"ih": "viseme_ih",
	"ou": "viseme_ou",
	"ee": "viseme_ee",
	"oh": "viseme_oh",
}

const DEFAULT_EXPRESSIONS := {
	"blink_left": "blinkLeft",
	"blink_right": "blinkRight",
	"happy": "happy",
	"sad": "sad",
	"angry": "angry",
	"surprised": "surprised",
	"neutral": "neutral",
}

## Smoothing parameters (seconds)
var attack_time := 0.06
var release_time := 0.12

## The merged mapping table (driver name -> VRM name), built once
var _full_map: Dictionary = {}

## Current smoothed weights keyed by VRM expression name
var _current_weights: Dictionary = {}

## Reusable result dictionary — avoid per-frame allocation
var _result: Dictionary = {}


func _init():
	_rebuild_map({}, {})


## Rebuild mapping from config dictionaries.
func load_from_config(config: ConfigLoader):
	var viseme_map := config.get_viseme_map()
	var expr_map := config.get_expression_map()
	_rebuild_map(viseme_map, expr_map)
	var smoothing := config.get_smoothing()
	attack_time = smoothing.get("attack_time", 0.06)
	release_time = smoothing.get("release_time", 0.12)


func _rebuild_map(viseme_map: Dictionary, expr_map: Dictionary):
	_full_map.clear()
	if viseme_map.size() > 0:
		_full_map.merge(viseme_map)
	else:
		_full_map.merge(DEFAULT_VISEMES)
	if expr_map.size() > 0:
		_full_map.merge(expr_map)
	else:
		_full_map.merge(DEFAULT_EXPRESSIONS)
	# Pre-populate result dict so we never allocate in the hot path
	_result.clear()
	for driver_name in _full_map:
		var vrm_name: String = _full_map[driver_name]
		_result[vrm_name] = 0.0


## Map a dictionary of driver weights to VRM blendshape weights with smoothing.
## Returns the same Dictionary reference each call (no allocation).
func map_and_smooth(driver_weights: Dictionary, delta: float) -> Dictionary:
	for driver_name in _full_map:
		var vrm_name: String = _full_map[driver_name]
		var target: float = driver_weights.get(driver_name, 0.0)
		if target < 0.0:
			target = 0.0
		elif target > 1.0:
			target = 1.0

		var current: float = _current_weights.get(vrm_name, 0.0)

		var speed: float
		if target > current:
			speed = 1.0 - exp(-delta / maxf(attack_time, 0.001))
		else:
			speed = 1.0 - exp(-delta / maxf(release_time, 0.001))

		var smoothed := current + (target - current) * speed
		if smoothed < 0.005:
			smoothed = 0.0

		_current_weights[vrm_name] = smoothed
		_result[vrm_name] = smoothed

	return _result


## Reset all weights to zero (e.g., when switching avatars)
func reset():
	_current_weights.clear()
	for vrm_name in _result:
		_result[vrm_name] = 0.0
