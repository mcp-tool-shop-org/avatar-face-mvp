## FFT-based viseme driver.
## Analyzes audio spectrum and maps frequency bands to the 5 VRM visemes.
## Attach to a node that has access to the audio bus with a SpectrumAnalyzer effect.
class_name VisemeDriver
extends RefCounted

## Frequency band ranges (Hz) for each viseme.
## These are rough approximations — good enough for convincing mouth movement.
## aa (open mouth) = low formant ~700-1000 Hz
## ee (wide mouth) = mid formant ~2000-2500 Hz
## ih (slightly open) = mid-low ~1500-1800 Hz
## oh (round mouth) = low-mid ~500-700 Hz
## ou (pursed lips) = low ~300-500 Hz
const VISEME_BANDS := {
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

var _spectrum: AudioEffectSpectrumAnalyzerInstance = null


func set_spectrum(spectrum_instance: AudioEffectSpectrumAnalyzerInstance):
	_spectrum = spectrum_instance


## Analyze current audio frame and return viseme weights.
## Returns: { "aa": float, "ih": float, "ou": float, "ee": float, "oh": float }
func get_viseme_weights() -> Dictionary:
	var weights := {
		"aa": 0.0,
		"ih": 0.0,
		"ou": 0.0,
		"ee": 0.0,
		"oh": 0.0,
	}

	if _spectrum == null:
		return weights

	var total_energy := 0.0

	for viseme_name in VISEME_BANDS:
		var band: Vector2 = VISEME_BANDS[viseme_name]
		var magnitude: float = _spectrum.get_magnitude_for_frequency_range(
			band.x, band.y
		).length()

		if magnitude < noise_gate:
			magnitude = 0.0
		else:
			magnitude = (magnitude - noise_gate) * sensitivity

		magnitude = clampf(magnitude, 0.0, 1.0)
		weights[viseme_name] = magnitude
		total_energy += magnitude

	# Normalize so total doesn't exceed 1.0 (mouth can't be in two shapes at once)
	if total_energy > 1.0:
		for key in weights:
			weights[key] /= total_energy

	return weights
