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
@onready var library_button: Button = %LibraryButton
@onready var library_panel: PanelContainer = %LibraryPanel
@onready var zoom_in_btn: Button = %ZoomInBtn
@onready var zoom_out_btn: Button = %ZoomOutBtn
@onready var cam_up_btn: Button = %CamUpBtn
@onready var cam_down_btn: Button = %CamDownBtn
@onready var tts_button: Button = %TtsButton
@onready var tts_panel: PanelContainer = %TtsPanel
@onready var tts_connect_btn: Button = %TtsConnectBtn
@onready var tts_close_btn: Button = %TtsCloseBtn
@onready var tts_voice_option: OptionButton = %TtsVoiceOption
@onready var tts_text_edit: TextEdit = %TtsTextEdit
@onready var tts_speak_btn: Button = %TtsSpeakBtn
@onready var tts_stop_btn: Button = %TtsStopBtn
@onready var tts_emotion_option: OptionButton = %TtsEmotionOption
@onready var tts_status: Label = %TtsStatus

var _tts_controller: TtsController = null


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
	library_button.pressed.connect(_on_library_toggle)
	library_panel.visible = false
	zoom_in_btn.pressed.connect(func(): _get_main().zoom_camera(-0.05))
	zoom_out_btn.pressed.connect(func(): _get_main().zoom_camera(0.05))
	cam_up_btn.pressed.connect(func(): _get_main().adjust_camera_height(0.05))
	cam_down_btn.pressed.connect(func(): _get_main().adjust_camera_height(-0.05))

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

	# TTS panel wiring
	tts_button.pressed.connect(_on_tts_toggle)
	tts_panel.visible = false
	tts_close_btn.pressed.connect(func(): tts_panel.visible = false; tts_button.text = "TTS Speak")
	tts_connect_btn.pressed.connect(_on_tts_connect)
	tts_speak_btn.pressed.connect(_on_tts_speak)
	tts_stop_btn.pressed.connect(_on_tts_stop)
	tts_speak_btn.disabled = true
	tts_stop_btn.disabled = true

	# Default voices until bridge connects
	var default_voices := ["am_fenrir", "af_sky", "bm_george", "bf_emma", "af_jessica", "am_eric"]
	for v in default_voices:
		tts_voice_option.add_item(v)

	# Populate TTS emotion dropdown
	var tts_emotions := ["(none)", "happy", "sad", "angry", "surprised"]
	for e in tts_emotions:
		tts_emotion_option.add_item(e)


func _get_main() -> Node3D:
	return get_parent() as Node3D


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

	# Signal indicator (with speech energy from presence systems)
	var speech_e := 0.0
	if _avatar_controller.has_method("get_speech_energy"):
		speech_e = _avatar_controller.get_speech_energy()
	if total_energy > 0.1:
		signal_label.text = "Signal: ACTIVE (%.0f%%)" % (speech_e * 100)
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


func _on_library_toggle():
	library_panel.visible = not library_panel.visible
	if library_panel.visible:
		library_panel.show_library()
		library_button.text = "Hide Library"
	else:
		library_button.text = "Avatar Library"


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

	# Blink + eye bone status
	if not diag.get("has_blinks", false):
		text += "!! BLINKS MISSING (needed for GREEN) !!\n"
	var has_eye_bones: bool = diag.get("has_eye_bones", false)
	text += "Eye bones: %s | Gaze: %s\n" % [
		"YES" if has_eye_bones else "NO (blendshape fallback)",
		"saccades active"]

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


## --- TTS Panel ---

func setup_tts(tts: TtsController):
	_tts_controller = tts
	_tts_controller.connected.connect(_on_tts_connected)
	_tts_controller.disconnected.connect(_on_tts_disconnected)
	_tts_controller.speaking_started.connect(_on_tts_speaking)
	_tts_controller.playback_started.connect(_on_tts_playback_started)
	_tts_controller.playback_finished.connect(_on_tts_playback_finished)
	_tts_controller.error_received.connect(_on_tts_error)
	_tts_controller.voices_received.connect(_on_tts_voices)
	_tts_controller.aside_available_changed.connect(_on_aside_available)


func _on_tts_toggle():
	tts_panel.visible = not tts_panel.visible
	tts_button.text = "Hide TTS" if tts_panel.visible else "TTS Speak"


func _on_tts_connect():
	if _tts_controller == null:
		tts_status.text = "No TTS controller"
		return
	if _tts_controller.is_connected():
		_tts_controller.disconnect_from_bridge()
		tts_connect_btn.text = "Connect"
		tts_status.text = "Disconnected"
		tts_speak_btn.disabled = true
	else:
		tts_status.text = "Connecting..."
		_tts_controller.connect_to_bridge()


func _on_tts_speak():
	if _tts_controller == null or not _tts_controller.is_connected():
		return
	var text: String = tts_text_edit.text.strip_edges()
	if text == "":
		tts_status.text = "Enter text first"
		return
	var voice: String = tts_voice_option.get_item_text(tts_voice_option.selected) if tts_voice_option.selected >= 0 else ""
	var emotion := ""
	if tts_emotion_option.selected > 0:  # 0 = "(none)"
		emotion = tts_emotion_option.get_item_text(tts_emotion_option.selected)
	_tts_controller.speak(text, voice, "ogg", emotion, 0.6)
	tts_speak_btn.disabled = true
	tts_stop_btn.disabled = false


func _on_tts_stop():
	if _tts_controller:
		_tts_controller.stop()
	tts_stop_btn.disabled = true
	tts_speak_btn.disabled = not (_tts_controller and _tts_controller.is_connected())


func _on_tts_connected():
	tts_connect_btn.text = "Disconnect"
	tts_speak_btn.disabled = false
	status_label.text = "TTS bridge connected"
	# Aside status updates once we get the status response
	tts_status.text = "Connected — ready to speak"


func _on_tts_disconnected():
	tts_connect_btn.text = "Connect"
	tts_status.text = "Disconnected"
	tts_speak_btn.disabled = true
	tts_stop_btn.disabled = true


func _on_tts_speaking(text: String):
	tts_status.text = "Synthesizing..."
	status_label.text = "TTS: synthesizing..."


func _on_tts_playback_started(path: String):
	tts_status.text = "Playing: " + path.get_file()
	status_label.text = "TTS: playing"
	tts_stop_btn.disabled = false


func _on_tts_playback_finished():
	tts_status.text = "Ready"
	status_label.text = "TTS: done"
	tts_speak_btn.disabled = not (_tts_controller and _tts_controller.is_connected())
	tts_stop_btn.disabled = true


func _on_tts_error(message: String):
	tts_status.text = "Error: " + message
	tts_speak_btn.disabled = not (_tts_controller and _tts_controller.is_connected())
	tts_stop_btn.disabled = true


func _on_tts_voices(voices: Array):
	tts_voice_option.clear()
	for v in voices:
		var label: String = v.get("name", v.get("id", "?"))
		tts_voice_option.add_item(label)
	if tts_voice_option.item_count > 0:
		# Select am_fenrir if available
		for i in tts_voice_option.item_count:
			if "fenrir" in tts_voice_option.get_item_text(i):
				tts_voice_option.selected = i
				return
		tts_voice_option.selected = 0


func _on_aside_available(available: bool):
	if available:
		tts_status.text = "Connected — aside active (expression cues)"
	else:
		tts_status.text = "Connected — aside unavailable"
