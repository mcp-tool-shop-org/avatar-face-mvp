## Main scene script.
## Handles VRM loading and scene setup.
extends Node3D

@onready var avatar_controller: Node3D = $AvatarController
@onready var demo_ui: Control = $DemoUI
@onready var camera: Camera3D = $Camera3D
@onready var avatar_mount: Node3D = $AvatarController/AvatarMount


func _ready():
	# Try to auto-load first VRM found in assets/avatars/
	_try_autoload_avatar()


func _try_autoload_avatar():
	var dir := DirAccess.open("res://assets/avatars/")
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".vrm"):
			var path := "res://assets/avatars/" + file_name
			_load_vrm(path)
			return
		file_name = dir.get_next()


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

	# Position camera to frame the face
	_frame_avatar(instance)

	demo_ui.status_label.text = "Loaded: " + path.get_file()
	print("Avatar loaded: ", path)


func _frame_avatar(avatar: Node3D):
	# VRM models are typically ~1.6m tall, face is around y=1.4
	# Position camera to look at the face
	camera.position = Vector3(0, 1.4, 1.0)
	camera.look_at(Vector3(0, 1.4, 0))
