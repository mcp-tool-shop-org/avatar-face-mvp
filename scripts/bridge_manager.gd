## BridgeManager — auto-starts the TTS bridge and connects.
##
## Behavior: probe WebSocket first (bridge might already be running),
## spawn bridge only if probe fails, retry with backoff, timeout gracefully.
## Cleans up the bridge process on exit.
class_name BridgeManager
extends Node

signal bridge_ready
signal bridge_failed(reason: String)
signal status_changed(message: String)

@export var ws_url: String = "ws://127.0.0.1:9200"
@export var auto_spawn: bool = true
@export var connect_timeout_sec: float = 15.0  ## Longer for cold Kokoro model load

var _bridge_pid: int = -1
var _spawned: bool = false
var _ready: bool = false


func is_bridge_ready() -> bool:
	return _ready


## Call this on startup. Probes, spawns if needed, retries until ready or timeout.
func ensure_bridge_running() -> bool:
	status_changed.emit("Checking for bridge...")

	# 1. Probe — maybe bridge is already running
	if await _probe_ws():
		_ready = true
		status_changed.emit("Bridge connected")
		bridge_ready.emit()
		return true

	# 2. Spawn if allowed
	if auto_spawn:
		status_changed.emit("Starting bridge...")
		_start_bridge()

	# 3. Retry until connected or timeout
	var deadline := Time.get_ticks_msec() + int(connect_timeout_sec * 1000.0)
	var attempt := 0
	while Time.get_ticks_msec() < deadline:
		attempt += 1
		# Backoff: 250ms, 500ms, 750ms, then 1s steady
		var wait := minf(0.25 * attempt, 1.0)
		await get_tree().create_timer(wait).timeout

		if await _probe_ws():
			_ready = true
			status_changed.emit("Bridge connected")
			bridge_ready.emit()
			return true

	# 4. Timed out
	var reason := "Bridge did not start within %.0fs" % connect_timeout_sec
	status_changed.emit(reason)
	bridge_failed.emit(reason)
	return false


## Lightweight WebSocket probe — connect, check state, close.
func _probe_ws() -> bool:
	var peer := WebSocketPeer.new()
	var err := peer.connect_to_url(ws_url)
	if err != OK:
		return false

	# Poll for up to 500ms waiting for OPEN
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 500:
		peer.poll()
		var state := peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			peer.close()
			return true
		if state == WebSocketPeer.STATE_CLOSED:
			return false
		await get_tree().process_frame

	# Timed out — close and report failure
	peer.close()
	return false


## Spawn the bridge process.
func _start_bridge() -> void:
	if _spawned:
		return
	_spawned = true

	var is_export := OS.has_feature("standalone") or OS.has_feature("template")

	var cmd: String
	var args: PackedStringArray

	if is_export:
		# Exported app: look for tts-bridge.exe next to the game exe
		var exe_dir := OS.get_executable_path().get_base_dir()
		var bridge_exe := exe_dir.path_join("tts-bridge.exe")
		if FileAccess.file_exists(bridge_exe):
			cmd = bridge_exe
			args = PackedStringArray()
		else:
			# Fallback: try node in PATH
			cmd = "node"
			args = PackedStringArray([exe_dir.path_join("tools/tts-bridge/bridge.mjs")])
	else:
		# Dev mode: run via node from project directory
		cmd = "node"
		var bridge_path := ProjectSettings.globalize_path("res://tools/tts-bridge/bridge.mjs")
		args = PackedStringArray([bridge_path])

	print("BridgeManager: spawning %s %s" % [cmd, " ".join(args)])
	_bridge_pid = OS.create_process(cmd, args, false)

	if _bridge_pid <= 0:
		push_warning("BridgeManager: failed to spawn bridge process")
		_spawned = false


## Kill the bridge process on exit.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_kill_bridge()


func _kill_bridge() -> void:
	if _spawned and _bridge_pid > 0:
		print("BridgeManager: killing bridge pid %d" % _bridge_pid)
		OS.kill(_bridge_pid)
		_bridge_pid = -1
