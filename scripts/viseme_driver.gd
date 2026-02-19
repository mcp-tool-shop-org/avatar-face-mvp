## FFT-based viseme driver.
## Analyzes audio spectrum and maps frequency bands to the 5 VRM visemes.
## Loads band ranges from config/tuning.json. Falls back to hardcoded defaults.
class_name VisemeDriver
extends RefCounted

## Default frequency band ranges (Hz) for each viseme.
const DEFAULT_BANDS := {
	"ou": Vector2(250.0, 500.0),
	"oh": Vector2(500.0, 750.0),
	"aa": Vector2(700.0, 1100.0),
	"ih": Vector2(1400.0, 1900.0),
	"ee": Vector2(1900.0, 2600.0),
}

## Minimum magnitude to register as speech (noise gate)
var noise_gate := 0.003
## Sensitivity multiplier
var sensitivity := 8.0

## Active band config (may be overridden by config file)
var _bands: Dictionary = {}

var _spectrum: AudioEffectSpectrumAnalyzerInstance = null

## Reusable weights dictionary — never reallocated
var _weights: Dictionary = {
	"aa": 0.0, "ih": 0.0, "ou": 0.0, "ee": 0.0, "oh": 0.0,
}


func _init():
	_bands = DEFAULT_BANDS.duplicate()


## Load band ranges + tuning from config.
func load_from_config(config: ConfigLoader):
	noise_gate = config.get_noise_gate()
	sensitivity = config.get_sensitivity()
	var cfg_bands := config.get_viseme_bands()
	if cfg_bands.size() > 0:
		_bands.clear()
		for key in cfg_bands:
			var arr = cfg_bands[key]
			if arr is Array and arr.size() >= 2:
				_bands[key] = Vector2(float(arr[0]), float(arr[1]))


func set_spectrum(spectrum_instance: AudioEffectSpectrumAnalyzerInstance):
	_spectrum = spectrum_instance


## Analyze current audio frame and return viseme weights.
## Returns the same Dictionary reference each call (no allocation).
func get_viseme_weights() -> Dictionary:
	# Zero out
	_weights["aa"] = 0.0
	_weights["ih"] = 0.0
	_weights["ou"] = 0.0
	_weights["ee"] = 0.0
	_weights["oh"] = 0.0

	if _spectrum == null:
		return _weights

	var total_energy := 0.0

	for viseme_name in _bands:
		var band: Vector2 = _bands[viseme_name]
		var magnitude: float = _spectrum.get_magnitude_for_frequency_range(
			band.x, band.y
		).length()

		if magnitude < noise_gate:
			magnitude = 0.0
		else:
			magnitude = (magnitude - noise_gate) * sensitivity

		if magnitude > 1.0:
			magnitude = 1.0

		_weights[viseme_name] = magnitude
		total_energy += magnitude

	# Normalize so total doesn't exceed 1.0
	if total_energy > 1.0:
		var inv := 1.0 / total_energy
		for key in _weights:
			_weights[key] *= inv

	return _weights
