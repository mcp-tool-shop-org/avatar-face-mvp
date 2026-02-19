## Main scene script.
## Handles VRM loading, avatar listing, and scene setup.
extends Node3D

@onready var avatar_controller: Node3D = $AvatarController
@onready var demo_ui: Control = $DemoUI
@onready var camera: Camera3D = $Camera3D
@onready var avatar_mount: Node3D = $AvatarController/AvatarMount

## List of available VRM files
var _avatar_list: PackedStringArray = []


func _ready():
	_scan_avatars()
	demo_ui.set_avatar_list(_avatar_list)
	if _avatar_list.size() > 0:
		load_avatar(0)


## Scan assets/avatars/ for .vrm files
func _scan_avatars():
	_avatar_list.clear()
	var dir: DirAccess = DirAccess.open("res://assets/avatars/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".vrm"):
			_avatar_list.append(file_name)
		file_name = dir.get_next()
	_avatar_list.sort()


## Load avatar by index in the list
func load_avatar(idx: int):
	if idx < 0 or idx >= _avatar_list.size():
		return
	var path := "res://assets/avatars/" + _avatar_list[idx]
	_load_vrm(path)


func _load_vrm(path: String):
	var resource = load(path)
	if resource == null:
		push_warning("Failed to load VRM: " + path)
		return

	var instance: Node3D = null
	if resource is PackedScene:
		instance = resource.instantiate()
	else:
		push_warning("VRM resource is not a PackedScene: " + path)
		return

	# Clear existing avatar
	for child in avatar_mount.get_children():
		child.queue_free()

	avatar_mount.add_child(instance)
	avatar_controller.setup_avatar(instance)

	_frame_avatar(instance)

	demo_ui.status_label.text = "Loaded: " + path.get_file()
	print("Avatar loaded: ", path)


func _frame_avatar(avatar: Node3D):
	# Tight close-up on face for lipsync demo
	camera.position = Vector3(0, 1.42, 0.32)
	camera.look_at(Vector3(0, 1.38, 0))
