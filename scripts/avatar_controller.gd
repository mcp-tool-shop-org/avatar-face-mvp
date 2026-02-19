## Main avatar controller.
## Wires together: VisemeDriver + BlinkController + ExpressionMapper -> VRM blendshapes.
## Attach this to the root of your scene.
extends Node3D

@export var avatar_path: NodePath
@export var emotion_weight: float = 0.0
@export var current_emotion: String = "happy"

var _viseme_driver := VisemeDriver.new()
var _blink_controller := BlinkController.new()
var _expression_mapper := ExpressionMapper.new()

var _avatar_node: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _blend_shape_names: PackedStringArray = []

# Audio bus setup
var _audio_bus_idx: int = -1
var _spectrum_effect: AudioEffectSpectrumAnalyzer = null


func _ready():
	_setup_audio_bus()
	# Avatar is loaded dynamically — see load_avatar()


func _setup_audio_bus():
	# Create or find the capture bus with spectrum analyzer
	_audio_bus_idx = AudioServer.get_bus_index("Capture")
	if _audio_bus_idx == -1:
		# Create the bus
		AudioServer.add_bus()
		_audio_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_audio_bus_idx, "Capture")
		AudioServer.set_bus_mute(_audio_bus_idx, true)  # Don't play back mic audio

	# Add spectrum analyzer effect if not present
	var has_spectrum := false
	for i in AudioServer.get_bus_effect_count(_audio_bus_idx):
		if AudioServer.get_bus_effect(_audio_bus_idx, i) is AudioEffectSpectrumAnalyzer:
			_spectrum_effect = AudioServer.get_bus_effect(_audio_bus_idx, i)
			var instance = AudioServer.get_bus_effect_instance(_audio_bus_idx, i)
			_viseme_driver.set_spectrum(instance)
			has_spectrum = true
			break

	if not has_spectrum:
		_spectrum_effect = AudioEffectSpectrumAnalyzer.new()
		_spectrum_effect.buffer_length = 0.05  # 50ms buffer — low latency
		_spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		AudioServer.add_bus_effect(_audio_bus_idx, _spectrum_effect)
		var idx = AudioServer.get_bus_effect_count(_audio_bus_idx) - 1
		var instance = AudioServer.get_bus_effect_instance(_audio_bus_idx, idx)
		_viseme_driver.set_spectrum(instance)


## Call this after a VRM is loaded into the scene tree.
func setup_avatar(avatar: Node3D):
	_avatar_node = avatar
	_mesh_instance = _find_mesh_instance(avatar)
	if _mesh_instance and _mesh_instance.mesh:
		_blend_shape_names.clear()
		for i in _mesh_instance.mesh.get_blend_shape_count():
			_blend_shape_names.append(_mesh_instance.mesh.get_blend_shape_name(i))
		print("Found %d blend shapes: %s" % [_blend_shape_names.size(), _blend_shape_names])
	else:
		push_warning("No MeshInstance3D with blend shapes found in avatar")
	_expression_mapper.reset()


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	# VRM models typically have the face mesh as a child MeshInstance3D
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh and mi.mesh.get_blend_shape_count() > 0:
			return mi
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result:
			return result
	return null


func _process(delta: float):
	if _mesh_instance == null:
		return

	# 1. Get viseme weights from FFT
	var driver_weights := _viseme_driver.get_viseme_weights()

	# 2. Get blink weights
	var blink_weights := _blink_controller.update(delta)
	driver_weights.merge(blink_weights)

	# 3. Add emotion from slider
	if current_emotion != "" and emotion_weight > 0.0:
		driver_weights[current_emotion] = emotion_weight

	# 4. Map and smooth everything
	var vrm_weights := _expression_mapper.map_and_smooth(driver_weights, delta)

	# 5. Apply to mesh
	_apply_weights(vrm_weights)


func _apply_weights(weights: Dictionary):
	for vrm_name in weights:
		var idx := _find_blend_shape_index(vrm_name)
		if idx >= 0:
			_mesh_instance.set_blend_shape_value(idx, weights[vrm_name])


func _find_blend_shape_index(name: String) -> int:
	# Try exact match first
	var idx := _blend_shape_names.find(name)
	if idx >= 0:
		return idx
	# Try case-insensitive
	var lower := name.to_lower()
	for i in _blend_shape_names.size():
		if _blend_shape_names[i].to_lower() == lower:
			return i
	return -1


## Get list of available blend shapes (for debug UI)
func get_blend_shape_list() -> PackedStringArray:
	return _blend_shape_names


## Get current audio bus index (for routing AudioStreamPlayer)
func get_capture_bus_index() -> int:
	return _audio_bus_idx
