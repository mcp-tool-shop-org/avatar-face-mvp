## Simple procedural blink controller.
## Returns blink_left and blink_right weights for natural-looking blinks.
class_name BlinkController
extends RefCounted

## Blink timing
var min_interval := 2.0
var max_interval := 6.0
var blink_duration := 0.15

var _timer := 0.0
var _next_blink := 3.0
var _blink_progress := -1.0  # -1 = not blinking
var _rng := RandomNumberGenerator.new()

## Reusable result — no per-frame allocation
var _result: Dictionary = {"blink_left": 0.0, "blink_right": 0.0}


func _init():
	_rng.randomize()
	_next_blink = _rng.randf_range(min_interval, max_interval)


## Load timing from config.
func load_from_config(config: ConfigLoader):
	var cfg: Dictionary = config.get_blink_config()
	min_interval = cfg.get("min_interval", 2.0)
	max_interval = cfg.get("max_interval", 6.0)
	blink_duration = cfg.get("duration", 0.15)


## Call every frame. Returns the same Dictionary reference each call.
func update(delta: float) -> Dictionary:
	var weight := 0.0

	if _blink_progress >= 0.0:
		_blink_progress += delta / blink_duration
		if _blink_progress <= 1.0:
			weight = _blink_progress
		elif _blink_progress <= 2.0:
			weight = 2.0 - _blink_progress
		else:
			_blink_progress = -1.0
			weight = 0.0
			_next_blink = _rng.randf_range(min_interval, max_interval)
			_timer = 0.0
	else:
		_timer += delta
		if _timer >= _next_blink:
			_blink_progress = 0.0

	_result["blink_left"] = weight
	_result["blink_right"] = weight
	return _result
