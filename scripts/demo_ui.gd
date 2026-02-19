## Demo harness UI controller.
## Provides: mic toggle, WAV playback, emotion slider, debug info.
extends Control

@export var avatar_controller_path: NodePath

var _avatar_controller: Node3D = null
var _mic_capture: AudioStreamPlayer = null
var _wav_player: AudioStreamPlayer = null
var _is_mic_active := false

@onready var mic_button: Button = %MicButton
@onready var wav_button: Button = %WavButton
@onready var emotion_slider: HSlider = %EmotionSlider
@onready var emotion_label: Label = %EmotionLabel
@onready var emotion_option: OptionButton = %EmotionOption
@onready var fps_label: Label = %FpsLabel
@onready var status_label: Label = %StatusLabel
@onready var blend_debug: Label = %BlendDebug
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_label: Label = %SensitivityLabel


func _ready():
	_avatar_controller = get_node_or_null(avatar_controller_path)

	mic_button.pressed.connect(_on_mic_toggle)
	wav_button.pressed.connect(_on_wav_load)
	emotion_slider.value_changed.connect(_on_emotion_changed)
	emotion_option.item_selected.connect(_on_emotion_selected)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	# Populate emotion dropdown
	var emotions := ["happy", "sad", "angry", "surprised"]
	for e in emotions:
		emotion_option.add_item(e)

	emotion_slider.min_value = 0.0
	emotion_slider.max_value = 1.0
	emotion_slider.step = 0.01
	emotion_slider.value = 0.0

	sensitivity_slider.min_value = 1.0
	sensitivity_slider.max_value = 30.0
	sensitivity_slider.step = 0.5
	sensitivity_slider.value = 8.0

	status_label.text = "Load a VRM or drop one in assets/avatars/"
	_update_sensitivity_label()


func _process(_delta: float):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	# Show active blend shape weights for debug
	if _avatar_controller:
		var mapper: ExpressionMapper = _avatar_controller._expression_mapper
		var weights = mapper._current_weights
		var lines := PackedStringArray()
		for key in weights:
			var val: float = weights[key]
			if val > 0.005:
				var bar := ""
				for i in int(val * 20):
					bar += "|"
				lines.append("%s: %.2f %s" % [key, val, bar])
		blend_debug.text = "\n".join(lines) if lines.size() > 0 else "(no active weights)"


func _on_mic_toggle():
	if _avatar_controller == null:
		status_label.text = "No avatar loaded"
		return

	_is_mic_active = not _is_mic_active

	if _is_mic_active:
		_start_mic_capture()
		mic_button.text = "Stop Mic"
		status_label.text = "Mic active — speak to drive visemes"
	else:
		_stop_mic_capture()
		mic_button.text = "Start Mic"
		status_label.text = "Mic stopped"


func _start_mic_capture():
	if _mic_capture:
		_mic_capture.queue_free()

	_mic_capture = AudioStreamPlayer.new()
	var mic_stream := AudioStreamMicrophone.new()
	_mic_capture.stream = mic_stream
	_mic_capture.bus = "Capture"
	add_child(_mic_capture)
	_mic_capture.play()


func _stop_mic_capture():
	if _mic_capture:
		_mic_capture.stop()
		_mic_capture.queue_free()
		_mic_capture = null


func _on_wav_load():
	if _avatar_controller == null:
		status_label.text = "No avatar loaded"
		return

	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.wav ; WAV Audio", "*.ogg ; OGG Audio"])
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_selected.connect(_on_wav_selected)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_wav_selected(path: String):
	if _wav_player:
		_wav_player.stop()
		_wav_player.queue_free()

	# Load the audio file
	var stream: AudioStream = null
	if path.ends_with(".wav"):
		stream = _load_wav(path)
	elif path.ends_with(".ogg"):
		stream = _load_ogg(path)

	if stream == null:
		status_label.text = "Failed to load: " + path.get_file()
		return

	_wav_player = AudioStreamPlayer.new()
	_wav_player.stream = stream
	_wav_player.bus = "Capture"
	add_child(_wav_player)
	_wav_player.play()
	status_label.text = "Playing: " + path.get_file()


func _load_wav(path: String) -> AudioStream:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var wav := AudioStreamWAV.new()
	# Basic WAV loading — skip header, read raw data
	# For a proper implementation you'd parse the RIFF header
	# For MVP, Godot can import WAVs directly if placed in project
	file.close()
	# Fallback: try loading as resource if it's in the project
	if ResourceLoader.exists(path):
		return load(path)
	status_label.text = "Place WAV in project folder for import, or use OGG"
	return null


func _load_ogg(path: String) -> AudioStream:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data := file.get_buffer(file.get_length())
	file.close()
	var ogg := AudioStreamOggVorbis.load_from_buffer(data)
	return ogg


func _on_emotion_changed(value: float):
	if _avatar_controller:
		_avatar_controller.emotion_weight = value
		emotion_label.text = "Emotion: %.0f%%" % (value * 100)


func _on_emotion_selected(idx: int):
	if _avatar_controller:
		_avatar_controller.current_emotion = emotion_option.get_item_text(idx)


func _on_sensitivity_changed(value: float):
	if _avatar_controller:
		_avatar_controller._viseme_driver.sensitivity = value
	_update_sensitivity_label()


func _update_sensitivity_label():
	sensitivity_label.text = "Sensitivity: %.1f" % sensitivity_slider.value
