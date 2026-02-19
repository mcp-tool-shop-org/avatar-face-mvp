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

var _vrm_loader := VrmRuntimeLoader.new()

## Parallel lists: display names + full paths
var _avatar_names: PackedStringArray = []
var _avatar_paths: PackedStringArray = []


func _ready():
	_scan_all_avatars()
	demo_ui.set_avatar_list(_avatar_names)

	# Wire up library UI
	var lib_panel: PanelContainer = demo_ui.library_panel
	if lib_panel.has_method("setup"):
		lib_panel.setup(catalog, download_mgr, self)
	lib_panel.avatar_load_requested.connect(load_avatar_by_path)

	if _avatar_names.size() > 0:
		load_avatar(0)


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


func _load_vrm(path: String):
	var instance: Node3D = _vrm_loader.load_vrm(path)
	if instance == null:
		push_warning("Failed to load VRM: " + path)
		demo_ui.status_label.text = "Failed to load: " + path.get_file()
		return

	# Clear existing avatar
	for child in avatar_mount.get_children():
		child.queue_free()

	avatar_mount.add_child(instance)
	avatar_controller.setup_avatar(instance)

	_frame_avatar(instance)

	demo_ui.status_label.text = "Loaded: " + path.get_file()
	demo_ui.on_avatar_loaded()
	print("Avatar loaded: ", path)


## Refresh avatar list (called after downloads complete)
func refresh_avatar_list():
	_scan_all_avatars()
	demo_ui.set_avatar_list(_avatar_names)


func _frame_avatar(avatar: Node3D):
	# Tight close-up on face for lipsync demo
	camera.position = Vector3(0, 1.42, 0.32)
	camera.look_at(Vector3(0, 1.38, 0))
