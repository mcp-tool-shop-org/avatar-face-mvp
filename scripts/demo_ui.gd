## Demo harness UI controller.
## Provides: mic toggle, WAV playback, emotion slider, driver toggle, debug info.
extends Control

@export var avatar_controller_path: NodePath

var _avatar_controller: Node3D = null
var _mic_capture: AudioStreamPlayer = null
var _wav_player: AudioStreamPlayer = null
var _is_mic_active := false

## Pre-allocated bar characters to avoid per-frame string concat
const BAR_CHARS := "||||||||||||||||||||"

## Throttle debug text updates (every N frames)
var _debug_frame_counter := 0
const DEBUG_UPDATE_INTERVAL := 3

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
@onready var driver_option: OptionButton = %DriverOption


func _ready():
	_avatar_controller = get_node_or_null(avatar_controller_path)

	mic_button.pressed.connect(_on_mic_toggle)
	wav_button.pressed.connect(_on_wav_load)
	emotion_slider.value_changed.connect(_on_emotion_changed)
	emotion_option.item_selected.connect(_on_emotion_selected)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	driver_option.item_selected.connect(_on_driver_selected)

	# Populate emotion dropdown
	var emotions := ["happy", "sad", "angry", "surprised"]
	for e in emotions:
		emotion_option.add_item(e)

	# Populate driver dropdown
	driver_option.add_item("FFT (Mic Audio)")
	driver_option.add_item("OpenSeeFace (Webcam)")

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

	# Throttle debug text updates — no need to rebuild strings at 60fps
	_debug_frame_counter += 1
	if _debug_frame_counter < DEBUG_UPDATE_INTERVAL:
		return
	_debug_frame_counter = 0

	if _avatar_controller == null:
		return

	var mapper: ExpressionMapper = _avatar_controller._expression_mapper
	var weights: Dictionary = mapper._current_weights
	var text := ""
	var has_any := false

	for key in weights:
		var val: float = weights[key]
		if val > 0.005:
			has_any = true
			var bar_len := int(val * 20)
			# Slice from pre-allocated string instead of building char by char
			text += "%s: %.2f %s\n" % [key, val, BAR_CHARS.substr(0, bar_len)]

	blend_debug.text = text if has_any else "(no active weights)"


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
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	file.close()
	if ResourceLoader.exists(path):
		return load(path)
	status_label.text = "Place WAV in project folder for import, or use OGG"
	return null


func _load_ogg(path: String) -> AudioStream:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var ogg: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_buffer(data)
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


func _on_driver_selected(idx: int):
	if _avatar_controller == null:
		return
	_avatar_controller.set_driver_mode(idx)
	if idx == 0:
		status_label.text = "Driver: FFT (mic audio)"
		sensitivity_slider.editable = true
	else:
		status_label.text = "Driver: OpenSeeFace — start tracker on port 11573"
		sensitivity_slider.editable = false
