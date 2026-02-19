## Main scene script.
## Handles VRM loading, avatar listing, and scene setup.
## Uses VrmRuntimeLoader for both editor-imported and runtime-downloaded VRMs.
extends Node3D

@onready var avatar_controller: Node3D = $AvatarController
@onready var demo_ui: Control = $DemoUI
@onready var camera: Camera3D = $Camera3D
@onready var avatar_mount: Node3D = $AvatarController/AvatarMount
@onready var catalog: AvatarCatalog = $AvatarCatalog
@onready var download_mgr: AvatarDownloadManager = $AvatarDownloadManager
@onready var tts_controller: TtsController = $TtsController
@onready var bridge_manager: BridgeManager = $BridgeManager

var _vrm_loader := VrmRuntimeLoader.new()
var _pose_corrector: PoseCorrector = null

## Parallel lists: display names + full paths
var _avatar_names: PackedStringArray = []
var _avatar_paths: PackedStringArray = []

## Camera zoom state
var _cam_distance := 0.32
var _cam_height := 1.42
var _cam_look_y := 1.38
const CAM_ZOOM_STEP := 0.05
const CAM_MIN_DIST := 0.10
const CAM_MAX_DIST := 2.0


func _ready():
	_scan_all_avatars()
	demo_ui.set_avatar_list(_avatar_names)

	# Wire up library UI
	var lib_panel: PanelContainer = demo_ui.library_panel
	if lib_panel.has_method("setup"):
		lib_panel.setup(catalog, download_mgr, self)
	lib_panel.avatar_load_requested.connect(load_avatar_by_path)

	# Wire up TTS controller + aside performance cues
	demo_ui.setup_tts(tts_controller)
	tts_controller.performance_cue_received.connect(_on_performance_cue)
	tts_controller.playback_finished.connect(_on_tts_playback_finished)

	if _avatar_names.size() > 0:
		load_avatar(0)

	# Auto-start bridge + auto-connect TTS (non-blocking)
	bridge_manager.status_changed.connect(_on_bridge_status)
	bridge_manager.bridge_ready.connect(_on_bridge_ready)
	bridge_manager.bridge_failed.connect(_on_bridge_failed)
	bridge_manager.ensure_bridge_running()


func _on_bridge_status(message: String):
	demo_ui.status_label.text = message


func _on_bridge_ready():
	print("Bridge ready — auto-connecting TTS")
	tts_controller.auto_connect = true
	tts_controller.connect_to_bridge()


func _on_bridge_failed(reason: String):
	push_warning("Bridge failed: %s" % reason)
	demo_ui.status_label.text = "Bridge unavailable — use TTS panel to connect manually"


## Scan bundled + downloaded avatars
func _scan_all_avatars():
	_avatar_names.clear()
	_avatar_paths.clear()
	_scan_dir("res://assets/avatars/")
	_scan_dir_user("user://avatars/")


func _scan_dir(dir_path: String):
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".vrm"):
			_avatar_names.append(file_name.get_basename())
			_avatar_paths.append(dir_path + file_name)
		file_name = dir.get_next()


func _scan_dir_user(dir_path: String):
	# user:// directory may not exist yet
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	_scan_dir(dir_path)


## Load avatar by index in the list
func load_avatar(idx: int):
	if idx < 0 or idx >= _avatar_paths.size():
		return
	_load_vrm(_avatar_paths[idx])


## Load avatar by full path (used by library UI)
func load_avatar_by_path(path: String):
	_load_vrm(path)


var _pending_load_path := ""

func _load_vrm(path: String):
	demo_ui.status_label.text = "Loading: " + path.get_file() + "..."

	# Clear existing avatar immediately (not queue_free) to avoid stale references
	for child in avatar_mount.get_children():
		avatar_mount.remove_child(child)
		child.free()

	# Defer the actual load to next frame so the tree is clean
	_pending_load_path = path
	call_deferred("_do_load_vrm")


func _do_load_vrm():
	var path: String = _pending_load_path
	_pending_load_path = ""
	if path == "":
		return

	var instance: Node3D = _vrm_loader.load_vrm(path)
	if instance == null:
		push_warning("Failed to load VRM: " + path)
		demo_ui.status_label.text = "Failed to load: " + path.get_file()
		return

	avatar_mount.add_child(instance)

	# Remove old pose corrector if it exists
	if _pose_corrector and is_instance_valid(_pose_corrector):
		_pose_corrector.queue_free()
		_pose_corrector = null

	# Fix T-pose arms: add a PoseCorrector node that applies rotation every frame
	_pose_corrector = PoseCorrector.new()
	instance.add_child(_pose_corrector)
	if _pose_corrector.setup(instance):
		print("Pose corrected: %s" % _pose_corrector.correction_details)

	avatar_controller.setup_avatar(instance)

	_frame_avatar(instance)

	demo_ui.status_label.text = "Loaded: " + path.get_file()
	demo_ui.on_avatar_loaded()
	print("Avatar loaded: ", path)


## Refresh avatar list (called after downloads complete)
func refresh_avatar_list():
	_scan_all_avatars()
	demo_ui.set_avatar_list(_avatar_names)


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(-CAM_ZOOM_STEP)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(CAM_ZOOM_STEP)
				get_viewport().set_input_as_handled()


## Zoom camera in (negative delta) or out (positive delta)
func zoom_camera(delta: float):
	_cam_distance = clampf(_cam_distance + delta, CAM_MIN_DIST, CAM_MAX_DIST)
	_apply_camera()


## Adjust camera height (for different avatar sizes)
func adjust_camera_height(delta: float):
	_cam_height += delta
	_cam_look_y += delta
	_apply_camera()


func _apply_camera():
	camera.position = Vector3(0, _cam_height, _cam_distance)
	camera.look_at(Vector3(0, _cam_look_y, 0))


func _frame_avatar(avatar: Node3D):
	# Reset to default close-up framing
	_cam_distance = 0.32
	_cam_height = 1.42
	_cam_look_y = 1.38
	_apply_camera()


## Handle aside performance cue — set expression target on avatar controller
func _on_performance_cue(cue: Dictionary):
	var emotion: String = cue.get("emotion", "neutral")
	var intensity: float = cue.get("intensity", 0.5)
	if emotion == "" or emotion == "neutral":
		return
	avatar_controller.set_expression_target(emotion, intensity, 0.3, 1.0)
	print("Performance cue: %s (%.0f%%)" % [emotion, intensity * 100])


## When TTS playback finishes, gently release the expression
func _on_tts_playback_finished():
	avatar_controller.clear_expression_target()
