## Demo harness UI controller.
## Provides: driver toggle, mic toggle, WAV playback, one-click test,
## avatar selector, emotion slider, signal indicator, debug info.
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
@onready var test_wav_button: Button = %TestWavButton
@onready var emotion_slider: HSlider = %EmotionSlider
@onready var emotion_label: Label = %EmotionLabel
@onready var emotion_option: OptionButton = %EmotionOption
@onready var fps_label: Label = %FpsLabel
@onready var status_label: Label = %StatusLabel
@onready var blend_debug: Label = %BlendDebug
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_label: Label = %SensitivityLabel
@onready var driver_option: OptionButton = %DriverOption
@onready var avatar_option: OptionButton = %AvatarOption
@onready var signal_label: Label = %SignalLabel
@onready var diag_button: Button = %DiagButton
@onready var diag_panel: PanelContainer = %DiagPanel
@onready var diag_label: Label = %DiagLabel
@onready var profile_option: OptionButton = %ProfileOption


func _ready():
	_avatar_controller = get_node_or_null(avatar_controller_path)

	mic_button.pressed.connect(_on_mic_toggle)
	wav_button.pressed.connect(_on_wav_load)
	test_wav_button.pressed.connect(_on_test_wav)
	emotion_slider.value_changed.connect(_on_emotion_changed)
	emotion_option.item_selected.connect(_on_emotion_selected)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	driver_option.item_selected.connect(_on_driver_selected)
	avatar_option.item_selected.connect(_on_avatar_selected)
	diag_button.pressed.connect(_on_diag_toggle)
	diag_panel.visible = false
	profile_option.item_selected.connect(_on_profile_selected)
	_populate_profiles()

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
	signal_label.text = "Signal: --"
	_update_sensitivity_label()


## Called by main.gd with the list of available VRM files
func set_avatar_list(avatars: PackedStringArray):
	avatar_option.clear()
	for a in avatars:
		avatar_option.add_item(a.get_basename())


func _process(_delta: float):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	# Throttle debug text updates
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
	var total_energy := 0.0

	for key in weights:
		var val: float = weights[key]
		if val > 0.005:
			has_any = true
			total_energy += val
			var bar_len := int(val * 20)
			text += "%s: %.2f %s\n" % [key, val, BAR_CHARS.substr(0, bar_len)]

	blend_debug.text = text if has_any else "(no active weights)"

	# Signal indicator
	if total_energy > 0.1:
		signal_label.text = "Signal: ACTIVE"
	elif total_energy > 0.01:
		signal_label.text = "Signal: low"
	else:
		signal_label.text = "Signal: silence"


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


func _on_test_wav():
	if _avatar_controller == null:
		status_label.text = "No avatar loaded"
		return

	# Play the bundled test vowels WAV
	var path := "res://assets/audio/test_vowels.wav"
	if not ResourceLoader.exists(path):
		status_label.text = "test_vowels.wav not found in assets/audio/"
		return

	if _wav_player:
		_wav_player.stop()
		_wav_player.queue_free()

	var stream: AudioStream = load(path)
	if stream == null:
		status_label.text = "Failed to load test_vowels.wav"
		return

	_wav_player = AudioStreamPlayer.new()
	_wav_player.stream = stream
	_wav_player.bus = "Capture"
	add_child(_wav_player)
	_wav_player.play()
	status_label.text = "Playing: test_vowels.wav (ou-oh-aa-ih-ee x2)"


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


func _on_avatar_selected(idx: int):
	var main_node = get_parent()
	if main_node.has_method("load_avatar"):
		main_node.load_avatar(idx)
	# Auto-refresh diagnostics if panel is open
	if diag_panel.visible:
		_refresh_diagnostics()


## Called by main.gd after a new avatar is loaded
func on_avatar_loaded():
	if diag_panel.visible:
		_refresh_diagnostics()


func _populate_profiles():
	if _avatar_controller == null:
		return
	profile_option.clear()
	var profiles: PackedStringArray = _avatar_controller.get_mapping_profiles()
	for p in profiles:
		profile_option.add_item(p)
	# Select active profile
	for i in profile_option.item_count:
		if profile_option.get_item_text(i) == _avatar_controller._config.active_profile:
			profile_option.selected = i
			break


func _on_profile_selected(idx: int):
	if _avatar_controller == null:
		return
	var profile_name: String = profile_option.get_item_text(idx)
	_avatar_controller.set_mapping_profile(profile_name)
	status_label.text = "Mapping: " + profile_name
	if diag_panel.visible:
		_refresh_diagnostics()


func _on_diag_toggle():
	diag_panel.visible = not diag_panel.visible
	if diag_panel.visible:
		_refresh_diagnostics()
		diag_button.text = "Hide Diagnostics"
	else:
		diag_button.text = "Model Diagnostics"


func _refresh_diagnostics():
	if _avatar_controller == null or not _avatar_controller.has_method("get_model_diagnostics"):
		diag_label.text = "No avatar loaded"
		return

	var diag: Dictionary = _avatar_controller.get_model_diagnostics()
	var text := ""

	# Status badge
	var status: String = diag.get("status", "none")
	var total: int = diag.get("total_shapes", 0)
	if status == "green":
		text += "[GREEN] Model ready (%d shapes)\n" % total
	elif status == "yellow":
		text += "[YELLOW] Partial coverage (%d shapes)\n" % total
	elif status == "red":
		text += "[RED] Missing critical shapes (%d shapes)\n" % total
	else:
		text += "No model loaded\n"

	# Style detection + profile suggestion
	var detected: String = diag.get("detected_style", "unknown")
	var suggested: String = diag.get("suggested_profile", "")
	var active_prof: String = diag.get("active_profile", "")
	text += "Style: %s | Profile: %s\n" % [detected.to_upper(), active_prof]
	if suggested != "":
		text += ">>> TRY SWITCHING TO: %s <<<\n" % suggested

	# Blink status
	if not diag.get("has_blinks", false):
		text += "!! BLINKS MISSING (needed for GREEN) !!\n"

	# Viseme coverage
	text += "\n--- VISEMES ---\n"
	var visemes: Array = diag.get("visemes", [])
	for v in visemes:
		var marker: String = "OK" if v["found"] else "MISS"
		text += "  %s -> %s [%s]\n" % [v["driver"], v["vrm_name"], marker]

	# Expression coverage
	text += "\n--- EXPRESSIONS ---\n"
	var expressions: Array = diag.get("expressions", [])
	for e in expressions:
		var marker: String = "OK" if e["found"] else "MISS"
		text += "  %s -> %s [%s]\n" % [e["driver"], e["vrm_name"], marker]

	# Unmapped shapes (categorized)
	var unmapped: Array = diag.get("unmapped", [])
	if unmapped.size() > 0:
		var mouth_shapes: PackedStringArray = []
		var eye_shapes: PackedStringArray = []
		var other_shapes: PackedStringArray = []
		for u in unmapped:
			var lower: String = u.to_lower()
			if "mouth" in lower or "jaw" in lower or "lip" in lower or "tongue" in lower:
				mouth_shapes.append(u)
			elif "eye" in lower or "blink" in lower or "brow" in lower or "cheek" in lower:
				eye_shapes.append(u)
			else:
				other_shapes.append(u)

		text += "\n--- UNMAPPED (%d) ---\n" % unmapped.size()
		if mouth_shapes.size() > 0:
			text += " [mouth/jaw]\n"
			for s in mouth_shapes:
				text += "  %s\n" % s
		if eye_shapes.size() > 0:
			text += " [eye/brow]\n"
			for s in eye_shapes:
				text += "  %s\n" % s
		if other_shapes.size() > 0:
			text += " [other]\n"
			for s in other_shapes:
				text += "  %s\n" % s

	diag_label.text = text
