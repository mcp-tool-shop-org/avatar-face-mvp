## Simple procedural blink controller.
## Returns blink_left and blink_right weights for natural-looking blinks.
class_name BlinkController
extends RefCounted

## Blink timing
var min_interval := 2.0  # Minimum seconds between blinks
var max_interval := 6.0  # Maximum seconds between blinks
var blink_duration := 0.15  # How long a blink takes (one way)

var _timer := 0.0
var _next_blink := 3.0
var _blink_progress := -1.0  # -1 = not blinking, 0..1 = blink progress
var _rng := RandomNumberGenerator.new()


func _init():
	_rng.randomize()
	_next_blink = _rng.randf_range(min_interval, max_interval)


## Call every frame. Returns { "blink_left": float, "blink_right": float }
func update(delta: float) -> Dictionary:
	var weight := 0.0

	if _blink_progress >= 0.0:
		# Currently blinking
		_blink_progress += delta / blink_duration
		if _blink_progress <= 1.0:
			# Closing
			weight = _blink_progress
		elif _blink_progress <= 2.0:
			# Opening
			weight = 2.0 - _blink_progress
		else:
			# Done
			_blink_progress = -1.0
			weight = 0.0
			_next_blink = _rng.randf_range(min_interval, max_interval)
			_timer = 0.0
	else:
		# Waiting for next blink
		_timer += delta
		if _timer >= _next_blink:
			_blink_progress = 0.0

	return {
		"blink_left": weight,
		"blink_right": weight,
	}
