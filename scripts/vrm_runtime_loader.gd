## Runtime VRM loader using GLTFDocument API.
## Handles both editor-imported (res://) and runtime-downloaded (user://) VRM files.
## Registers VRM 0.0 + 1.0 extensions per addons/vrm/plugin.gd:203-209.
class_name VrmRuntimeLoader
extends RefCounted

const vrm_extension_class = preload("res://addons/vrm/vrm_extension.gd")
const VRMC_vrm_class = preload("res://addons/vrm/1.0/VRMC_vrm.gd")
const VRMC_node_constraint_class = preload("res://addons/vrm/1.0/VRMC_node_constraint.gd")
const VRMC_springBone_class = preload("res://addons/vrm/1.0/VRMC_springBone.gd")
const VRMC_materials_hdr_class = preload(
	"res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd"
)
const VRMC_materials_mtoon_class = preload("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")

## EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS = 16
const IMPORT_USE_NAMED_SKIN_BINDS := 16


## Load a VRM file and return the instantiated Node3D scene.
## For res:// paths with existing .import, uses Godot's resource loader.
## For user:// or unimported paths, uses GLTFDocument runtime pipeline.
func load_vrm(path: String) -> Node3D:
	# Editor-imported resources: use fast path
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource = load(path)
		if resource is PackedScene:
			return resource.instantiate()
		push_warning("VRM resource is not a PackedScene: " + path)
		return null

	# Runtime loading via GLTFDocument
	return _load_vrm_runtime(path)


func _load_vrm_runtime(path: String) -> Node3D:
	# Convert user:// to absolute path for GLTFDocument
	var abs_path: String = path
	if path.begins_with("user://"):
		abs_path = ProjectSettings.globalize_path(path)

	if not FileAccess.file_exists(path):
		push_warning("VRM file not found: " + path)
		return null

	var gltf := GLTFDocument.new()

	# Register VRM 0.0 extension (handles both 0.0 and dispatches to 1.0)
	var vrm_ext: GLTFDocumentExtension = vrm_extension_class.new()
	gltf.register_gltf_document_extension(vrm_ext, true)

	# Register VRM 1.0 extensions (same set as plugin.gd:205-209)
	var vrm1_exts: Array = [
		VRMC_vrm_class.new(),
		VRMC_node_constraint_class.new(),
		VRMC_springBone_class.new(),
		VRMC_materials_hdr_class.new(),
		VRMC_materials_mtoon_class.new(),
	]
	for ext in vrm1_exts:
		gltf.register_gltf_document_extension(ext)

	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED

	var err: int = gltf.append_from_file(abs_path, state, IMPORT_USE_NAMED_SKIN_BINDS)

	# Cleanup extensions regardless of outcome
	gltf.unregister_gltf_document_extension(vrm_ext)
	for ext in vrm1_exts:
		gltf.unregister_gltf_document_extension(ext)

	if err != OK:
		push_warning("VRM runtime load failed (error %d): %s" % [err, path])
		return null

	var scene: Node = gltf.generate_scene(state)
	if scene is Node3D:
		return scene
	if scene:
		scene.queue_free()
	push_warning("VRM generated scene is not Node3D: " + path)
	return null
