## TTS Controller — bridges to the tts-bridge WebSocket server.
## Sends speak requests, receives audio file paths, plays through Capture bus
## so the existing FFT viseme pipeline drives the avatar's face.
class_name TtsController
extends Node

signal connected
signal disconnected
signal speaking_started(text: String)
signal playback_started(path: String)
signal playback_finished
signal error_received(message: String)
signal status_received(data: Dictionary)
signal voices_received(voices: Array)
signal performance_cue_received(cue: Dictionary)
signal aside_available_changed(available: bool)

@export var bridge_url := "ws://localhost:9200"
@export var auto_connect := false
@export var capture_bus := "Capture"

var _ws := WebSocketPeer.new()
var _connected := false
var _connecting := false
var _audio_player: AudioStreamPlayer = null
var _audio_queue: Array = []  # Queue of {path, voice, text, durationMs}
var _is_playing := false
var _available_voices: Array = []
var _aside_available := false

## Reconnect timer
var _reconnect_timer := 0.0
const RECONNECT_INTERVAL := 3.0


func _ready():
	if auto_connect:
		connect_to_bridge()


func _process(delta: float):
	if _connecting or _connected:
		_ws.poll()
		var state := _ws.get_ready_state()

		match state:
			WebSocketPeer.STATE_OPEN:
				if not _connected:
					_connected = true
					_connecting = false
					print("TtsController: connected to bridge")
					connected.emit()
					# Request voice list on connect
					_send({"type": "status"})

				# Read all available messages
				while _ws.get_available_packet_count() > 0:
					var packet := _ws.get_packet()
					_handle_message(packet.get_string_from_utf8())

			WebSocketPeer.STATE_CLOSING:
				pass

			WebSocketPeer.STATE_CLOSED:
				if _connected:
					_connected = false
					_connecting = false
					print("TtsController: disconnected (code %d)" % _ws.get_close_code())
					disconnected.emit()

				# Auto-reconnect
				if auto_connect:
					_reconnect_timer += delta
					if _reconnect_timer >= RECONNECT_INTERVAL:
						_reconnect_timer = 0.0
						connect_to_bridge()

	# Check if current audio finished playing
	if _is_playing and _audio_player and not _audio_player.playing:
		_is_playing = false
		playback_finished.emit()
		_play_next_in_queue()


func connect_to_bridge():
	if _connected or _connecting:
		return
	_connecting = true
	_reconnect_timer = 0.0
	var err := _ws.connect_to_url(bridge_url)
	if err != OK:
		_connecting = false
		push_warning("TtsController: failed to connect to %s (error %d)" % [bridge_url, err])


func disconnect_from_bridge():
	if _connected:
		_ws.close()
	_connected = false
	_connecting = false
	auto_connect = false


func is_bridge_connected() -> bool:
	return _connected


func is_playing() -> bool:
	return _is_playing


func get_available_voices() -> Array:
	return _available_voices


## Send a speak request to the bridge.
## emotion/intensity are forwarded so the bridge can push an aside performance cue.
func speak(
	text: String,
	voice: String = "",
	format: String = "ogg",
	emotion: String = "",
	intensity: float = 0.5
):
	if not _connected:
		error_received.emit("Not connected to TTS bridge")
		return
	var msg := {"type": "speak", "text": text, "format": format}
	if voice != "":
		msg["voice"] = voice
	if emotion != "":
		msg["emotion"] = emotion
		msg["intensity"] = intensity
	_send(msg)


## Send a dialogue request.
func speak_dialogue(script: String, cast: Dictionary = {}, format: String = "ogg"):
	if not _connected:
		error_received.emit("Not connected to TTS bridge")
		return
	_send({"type": "dialogue", "script": script, "cast": cast, "format": format})


## Stop current synthesis/playback.
func stop():
	_audio_queue.clear()
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
	_is_playing = false
	if _connected:
		_send({"type": "stop"})
	playback_finished.emit()


## Request voice list from bridge.
func request_status():
	if _connected:
		_send({"type": "status"})


func _send(data: Dictionary):
	var json := JSON.stringify(data)
	_ws.send_text(json)


func _handle_message(text: String):
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("TtsController: bad JSON from bridge")
		return
	var msg: Dictionary = json.data
	if not msg is Dictionary:
		return

	var msg_type: String = msg.get("type", "")

	match msg_type:
		"tts.play":
			var path: String = msg.get("path", "")
			var voice: String = msg.get("voice", "")
			var spoken_text: String = msg.get("text", "")
			var duration_ms: int = msg.get("durationMs", 0)
			if path != "":
				(
					_audio_queue
					. append(
						{
							"path": path,
							"voice": voice,
							"text": spoken_text,
							"durationMs": duration_ms,
						}
					)
				)
				if not _is_playing:
					_play_next_in_queue()

		"tts.speaking":
			speaking_started.emit(msg.get("text", ""))

		"tts.stopped":
			_audio_queue.clear()
			if _audio_player and _audio_player.playing:
				_audio_player.stop()
			_is_playing = false
			playback_finished.emit()

		"tts.error":
			var err_msg: String = msg.get("message", "Unknown error")
			var err_code: String = msg.get("code", "")
			push_warning("TtsController: %s (%s)" % [err_msg, err_code])
			error_received.emit(err_msg)

		"tts.status":
			var voices: Array = msg.get("voices", [])
			_available_voices = voices
			voices_received.emit(voices)
			status_received.emit(msg)
			# Track aside availability from status response
			var aside_avail: bool = msg.get("asideAvailable", false)
			if aside_avail != _aside_available:
				_aside_available = aside_avail
				aside_available_changed.emit(_aside_available)

		"aside.item":
			# Performance cue from aside inbox
			var meta: Dictionary = msg.get("meta", {})
			var cue := {
				"id": msg.get("id", ""),
				"text": msg.get("text", ""),
				"priority": msg.get("priority", "med"),
				"emotion": meta.get("emotion", "neutral"),
				"intensity": float(meta.get("intensity", 0.5)),
				"mode": meta.get("mode", ""),
				"voice": meta.get("voice", ""),
				"audioPath": meta.get("audioPath", ""),
				"durationMs": int(meta.get("durationMs", 0)),
				"tags": msg.get("tags", []),
			}
			performance_cue_received.emit(cue)

		"aside.inbox":
			var items: Array = msg.get("items", [])
			for item in items:
				var item_meta: Dictionary = item.get("meta", {})
				var cue := {
					"id": item.get("id", ""),
					"text": item.get("text", ""),
					"priority": item.get("priority", "med"),
					"emotion": item_meta.get("emotion", "neutral"),
					"intensity": float(item_meta.get("intensity", 0.5)),
					"mode": item_meta.get("mode", ""),
					"tags": item.get("tags", []),
				}
				performance_cue_received.emit(cue)

		"aside.status":
			var avail: bool = msg.get("available", false)
			if avail != _aside_available:
				_aside_available = avail
				aside_available_changed.emit(_aside_available)
			status_received.emit(msg)


func _play_next_in_queue():
	if _audio_queue.size() == 0:
		return

	var item: Dictionary = _audio_queue.pop_front()
	var path: String = item["path"]

	# Load the audio file from the absolute filesystem path
	var stream := _load_audio_file(path)
	if stream == null:
		push_warning("TtsController: failed to load audio: %s" % path)
		error_received.emit("Failed to load audio file")
		_play_next_in_queue()
		return

	# Ensure we have a player
	if _audio_player == null:
		_audio_player = AudioStreamPlayer.new()
		_audio_player.bus = capture_bus
		add_child(_audio_player)

	_audio_player.stream = stream
	_audio_player.play()
	_is_playing = true
	playback_started.emit(path)
	print("TtsController: playing %s" % path.get_file())


## --- Aside helpers ---


func is_aside_available() -> bool:
	return _aside_available


## Push a performance cue to aside via bridge.
func push_aside(
	text: String, emotion: String = "neutral", intensity: float = 0.5, tags: Array = []
):
	if not _connected:
		return
	var msg := {
		"type": "aside",
		"action": "push",
		"text": text,
		"priority": "med",
		"emotion": emotion,
		"intensity": intensity,
		"tags": tags,
	}
	_send(msg)


## Request the current aside inbox contents.
func read_inbox():
	if not _connected:
		return
	_send({"type": "aside", "action": "inbox"})


## Clear the aside inbox.
func clear_inbox():
	if not _connected:
		return
	_send({"type": "aside", "action": "clear"})


## Load an audio file from an absolute filesystem path.
## Supports OGG and WAV formats.
func _load_audio_file(path: String) -> AudioStream:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data := file.get_buffer(file.get_length())
	file.close()

	if path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_buffer(data)
	elif path.ends_with(".wav"):
		# WAV from absolute path — use runtime loading
		return _load_wav_from_buffer(data)
	elif path.ends_with(".mp3"):
		var mp3 := AudioStreamMP3.new()
		mp3.data = data
		return mp3

	push_warning("TtsController: unsupported format: %s" % path.get_extension())
	return null


## Parse WAV from raw bytes (PCM 16-bit expected from TTS).
func _load_wav_from_buffer(data: PackedByteArray) -> AudioStream:
	# Minimal WAV parser — expects standard RIFF/WAVE PCM
	if data.size() < 44:
		return null
	# Check RIFF header
	if data[0] != 0x52 or data[1] != 0x49 or data[2] != 0x46 or data[3] != 0x46:
		return null

	# Read format chunk
	var num_channels: int = data[22] | (data[23] << 8)
	var sample_rate: int = data[24] | (data[25] << 8) | (data[26] << 16) | (data[27] << 24)
	var bits_per_sample: int = data[34] | (data[35] << 8)

	# Find data chunk
	var pos := 12
	while pos + 8 < data.size():
		var chunk_id := ""
		for i in 4:
			chunk_id += String.chr(data[pos + i])
		var chunk_size: int = (
			data[pos + 4] | (data[pos + 5] << 8) | (data[pos + 6] << 16) | (data[pos + 7] << 24)
		)
		if chunk_id == "data":
			var audio_data := data.slice(pos + 8, pos + 8 + chunk_size)
			var wav := AudioStreamWAV.new()
			wav.format = (
				AudioStreamWAV.FORMAT_16_BITS
				if bits_per_sample == 16
				else AudioStreamWAV.FORMAT_8_BITS
			)
			wav.mix_rate = sample_rate
			wav.stereo = num_channels == 2
			wav.data = audio_data
			return wav
		pos += 8 + chunk_size
		if chunk_size % 2 == 1:
			pos += 1  # WAV chunks are word-aligned

	return null
