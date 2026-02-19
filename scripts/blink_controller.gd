## Context-aware procedural blink controller.
## Triggers blinks from: baseline random timer, head saccades, speech pauses,
## and produces subtle asymmetric blinks for realism.
class_name BlinkController
extends RefCounted

## Blink timing
var min_interval := 2.0
var max_interval := 6.0
var blink_duration := 0.15

## Asymmetry: one eye leads the other by this many seconds (subtle)
var asymmetry_lead := 0.012  # ~12ms

## Context trigger weights
var saccade_blink_chance := 0.6  # probability of blink on large head saccade
var speech_pause_blink_chance := 0.5  # probability of blink when speech stops

## State
var _timer := 0.0
var _next_blink := 3.0
var _blink_progress := -1.0  # -1 = not blinking
var _lead_eye := 0  # 0 = left leads, 1 = right leads
var _rng := RandomNumberGenerator.new()

## Speech state tracking
var _was_speaking := false
var _speech_silence_timer := 0.0
const SPEECH_PAUSE_THRESHOLD := 0.3  # seconds of silence before "pause blink"

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
## speech_energy: 0-1 audio energy (pass 0 if no audio active).
func update(delta: float, speech_energy: float = 0.0) -> Dictionary:
	# Track speech state for pause-triggered blinks
	var is_speaking := speech_energy > 0.03
	if _was_speaking and not is_speaking:
		_speech_silence_timer = 0.0
	if not is_speaking:
		_speech_silence_timer += delta
		if _was_speaking and _speech_silence_timer >= SPEECH_PAUSE_THRESHOLD:
			# Speech just paused — trigger blink with probability
			if _blink_progress < 0.0 and _rng.randf() < speech_pause_blink_chance:
				_trigger_blink()
			_was_speaking = false
	else:
		_was_speaking = true
		_speech_silence_timer = 0.0

	# Baseline random timer
	if _blink_progress < 0.0:
		_timer += delta
		if _timer >= _next_blink:
			_trigger_blink()

	# Animate blink
	var left_weight := 0.0
	var right_weight := 0.0

	if _blink_progress >= 0.0:
		_blink_progress += delta / blink_duration

		# Compute base weight (triangle: 0→1→0 over progress 0→2)
		var base_weight: float
		if _blink_progress <= 1.0:
			base_weight = _blink_progress
		elif _blink_progress <= 2.0:
			base_weight = 2.0 - _blink_progress
		else:
			base_weight = 0.0
			_blink_progress = -1.0
			_next_blink = _rng.randf_range(min_interval, max_interval)
			_timer = 0.0

		if _blink_progress >= 0.0:
			# Asymmetry: leading eye is slightly ahead
			var lead_offset := asymmetry_lead / blink_duration
			var lag_progress := maxf(_blink_progress - lead_offset, 0.0)
			var lag_weight: float
			if lag_progress <= 1.0:
				lag_weight = lag_progress
			elif lag_progress <= 2.0:
				lag_weight = 2.0 - lag_progress
			else:
				lag_weight = 0.0

			if _lead_eye == 0:
				left_weight = base_weight
				right_weight = lag_weight
			else:
				right_weight = base_weight
				left_weight = lag_weight

	_result["blink_left"] = left_weight
	_result["blink_right"] = right_weight
	return _result


## External trigger: call when a large head saccade is detected.
func on_head_saccade():
	if _blink_progress < 0.0 and _rng.randf() < saccade_blink_chance:
		_trigger_blink()


## Force a blink immediately (used by external systems).
func force_blink():
	_trigger_blink()


func _trigger_blink():
	_blink_progress = 0.0
	_timer = 0.0
	# Randomly pick which eye leads
	_lead_eye = _rng.randi_range(0, 1)
