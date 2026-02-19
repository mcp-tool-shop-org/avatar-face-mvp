## Main avatar controller.
## Wires together: VisemeDriver/OpenSeeFaceDriver + BlinkController + IdleController
## + ExpressionMapper -> VRM blendshapes + skeleton bones.
## Supports driver switching at runtime. Loads config from JSON files.
extends Node3D

enum DriverMode { FFT, OPENSEEFACE }

@export var avatar_path: NodePath
@export var emotion_weight: float = 0.0
@export var current_emotion: String = "happy"

var _config := ConfigLoader.new()
var _viseme_driver := VisemeDriver.new()
var _osf_driver := OpenSeeFaceDriver.new()
var _blink_controller := BlinkController.new()
var _expression_mapper := ExpressionMapper.new()
var _idle_controller := IdleController.new()

var _driver_mode: int = DriverMode.FFT

var _avatar_node: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _blend_shape_names: PackedStringArray = []

## Cached blend shape name -> index lookup (avoids per-frame string search)
var _blend_shape_cache: Dictionary = {}

## Reusable merged driver weights dict — avoids per-frame allocation
var _merged_weights: Dictionary = {}

# Audio bus setup
var _audio_bus_idx: int = -1
var _spectrum_effect: AudioEffectSpectrumAnalyzer = null

# Config hot-reload timer
var _config_check_timer := 0.0
const CONFIG_CHECK_INTERVAL := 2.0

# Head pose smoothing
var _smoothed_head_rotation := Vector3.ZERO
var _head_pose_attack := 0.08
var _head_pose_release := 0.15


func _ready():
	_apply_config()
	_setup_audio_bus()


func _apply_config():
	_viseme_driver.load_from_config(_config)
	_blink_controller.load_from_config(_config)
	_expression_mapper.load_from_config(_config)
	var osf_cfg: Dictionary = _config.get_openseeface_config()
	_osf_driver.host = osf_cfg.get("host", "127.0.0.1")
	_osf_driver.port = int(osf_cfg.get("port", 11573))


func _setup_audio_bus():
	_audio_bus_idx = AudioServer.get_bus_index("Capture")
	if _audio_bus_idx == -1:
		AudioServer.add_bus()
		_audio_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_audio_bus_idx, "Capture")
		AudioServer.set_bus_mute(_audio_bus_idx, true)

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
		_spectrum_effect.buffer_length = 0.05
		_spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		AudioServer.add_bus_effect(_audio_bus_idx, _spectrum_effect)
		var idx = AudioServer.get_bus_effect_count(_audio_bus_idx) - 1
		var instance = AudioServer.get_bus_effect_instance(_audio_bus_idx, idx)
		_viseme_driver.set_spectrum(instance)


## Call this after a VRM is loaded into the scene tree.
func setup_avatar(avatar: Node3D):
	_avatar_node = avatar
	_mesh_instance = _find_mesh_instance(avatar)
	_blend_shape_cache.clear()
	if _mesh_instance and _mesh_instance.mesh:
		_blend_shape_names.clear()
		for i in _mesh_instance.mesh.get_blend_shape_count():
			var bs_name: String = _mesh_instance.mesh.get_blend_shape_name(i)
			_blend_shape_names.append(bs_name)
			_blend_shape_cache[bs_name] = i
			_blend_shape_cache[bs_name.to_lower()] = i
		print("Found %d blend shapes: %s" % [_blend_shape_names.size(), _blend_shape_names])
	else:
		push_warning("No MeshInstance3D with blend shapes found in avatar")
	_expression_mapper.reset()
	_idle_controller.setup(avatar)
	_smoothed_head_rotation = Vector3.ZERO


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh and mi.mesh.get_blend_shape_count() > 0:
			return mi
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result:
			return result
	return null


func set_driver_mode(mode: int):
	if mode == _driver_mode:
		return
	if _driver_mode == DriverMode.OPENSEEFACE:
		_osf_driver.stop()
	_driver_mode = mode
	if _driver_mode == DriverMode.OPENSEEFACE:
		_osf_driver.start()
	_expression_mapper.reset()
	_smoothed_head_rotation = Vector3.ZERO


func get_driver_mode() -> int:
	return _driver_mode


func _process(delta: float):
	if _mesh_instance == null:
		return

	# Periodic config hot-reload check
	_config_check_timer += delta
	if _config_check_timer >= CONFIG_CHECK_INTERVAL:
		_config_check_timer = 0.0
		if _config.check_hot_reload():
			_apply_config()
			print("Config reloaded")

	# 1. Get viseme weights from active driver
	_merged_weights.clear()

	if _driver_mode == DriverMode.FFT:
		var visemes := _viseme_driver.get_viseme_weights()
		_merged_weights.merge(visemes)
		var blink := _blink_controller.update(delta)
		_merged_weights.merge(blink)
	else:
		_osf_driver.poll()
		var visemes := _osf_driver.get_viseme_weights()
		_merged_weights.merge(visemes)
		var expressions := _osf_driver.get_expression_weights()
		_merged_weights.merge(expressions)

		# Apply head pose from tracker with smoothing
		var target_rot := _osf_driver.head_rotation
		var speed_x: float
		var speed_y: float
		var speed_z: float
		if abs(target_rot.x) > abs(_smoothed_head_rotation.x):
			speed_x = 1.0 - exp(-delta / _head_pose_attack)
		else:
			speed_x = 1.0 - exp(-delta / _head_pose_release)
		if abs(target_rot.y) > abs(_smoothed_head_rotation.y):
			speed_y = 1.0 - exp(-delta / _head_pose_attack)
		else:
			speed_y = 1.0 - exp(-delta / _head_pose_release)
		if abs(target_rot.z) > abs(_smoothed_head_rotation.z):
			speed_z = 1.0 - exp(-delta / _head_pose_attack)
		else:
			speed_z = 1.0 - exp(-delta / _head_pose_release)
		_smoothed_head_rotation.x = lerpf(_smoothed_head_rotation.x, target_rot.x, speed_x)
		_smoothed_head_rotation.y = lerpf(_smoothed_head_rotation.y, target_rot.y, speed_y)
		_smoothed_head_rotation.z = lerpf(_smoothed_head_rotation.z, target_rot.z, speed_z)
		_idle_controller.apply_head_pose(_smoothed_head_rotation)

	# 2. Add emotion from slider
	if current_emotion.length() > 0 and emotion_weight > 0.0:
		_merged_weights[current_emotion] = emotion_weight

	# 3. Map and smooth everything
	var vrm_weights := _expression_mapper.map_and_smooth(_merged_weights, delta)

	# 4. Apply to mesh (using cached index lookup)
	for vrm_name in vrm_weights:
		var idx: int = _blend_shape_cache.get(vrm_name, -1)
		if idx < 0:
			idx = _blend_shape_cache.get(vrm_name.to_lower(), -1)
		if idx >= 0:
			_mesh_instance.set_blend_shape_value(idx, vrm_weights[vrm_name])

	# 5. Idle animation (breathing, sway) — runs in both driver modes
	_idle_controller.update(delta)


## Get list of available blend shapes (for debug UI)
func get_blend_shape_list() -> PackedStringArray:
	return _blend_shape_names


## Get current audio bus index (for routing AudioStreamPlayer)
func get_capture_bus_index() -> int:
	return _audio_bus_idx
