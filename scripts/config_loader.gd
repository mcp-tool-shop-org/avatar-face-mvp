## Loads and provides access to JSON config files.
## Supports hot-reload by checking file modification time.
class_name ConfigLoader
extends RefCounted

const TUNING_PATH := "res://config/tuning.json"
const MAPPING_DIR := "res://config/"

## Available mapping profiles: name -> file path
var mapping_profiles: Dictionary = {}
var active_profile: String = ""

var mapping: Dictionary = {}
var tuning: Dictionary = {}

var _mapping_mtime := 0
var _tuning_mtime := 0


func _init():
	_scan_mapping_profiles()
	reload()


func _scan_mapping_profiles():
	mapping_profiles.clear()
	var dir: DirAccess = DirAccess.open(MAPPING_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("mapping") and file_name.ends_with(".json"):
			var profile_name: String = file_name.replace("mapping_", "").replace("mapping", "vrm").replace(".json", "")
			if profile_name == "vrm":
				profile_name = "VRM Standard"
			else:
				profile_name = profile_name.to_upper()
			mapping_profiles[profile_name] = MAPPING_DIR + file_name
		file_name = dir.get_next()
	if active_profile == "" and mapping_profiles.size() > 0:
		active_profile = "VRM Standard" if mapping_profiles.has("VRM Standard") else mapping_profiles.keys()[0]


func get_profile_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for key in mapping_profiles:
		names.append(key)
	names.sort()
	return names


func set_active_profile(profile_name: String):
	if mapping_profiles.has(profile_name):
		active_profile = profile_name
		var path: String = mapping_profiles[profile_name]
		mapping = _load_json(path)
		_mapping_mtime = _get_mtime(path)


func get_active_mapping_path() -> String:
	if mapping_profiles.has(active_profile):
		return mapping_profiles[active_profile]
	return MAPPING_DIR + "mapping.json"


func reload():
	mapping = _load_json(get_active_mapping_path())
	tuning = _load_json(TUNING_PATH)


## Check if files changed and reload if so. Call periodically (not every frame).
func check_hot_reload() -> bool:
	var changed := false
	var m_path: String = get_active_mapping_path()
	var m_time := _get_mtime(m_path)
	if m_time != _mapping_mtime:
		_mapping_mtime = m_time
		mapping = _load_json(m_path)
		changed = true
	var t_time := _get_mtime(TUNING_PATH)
	if t_time != _tuning_mtime:
		_tuning_mtime = t_time
		tuning = _load_json(TUNING_PATH)
		changed = true
	return changed


func get_viseme_map() -> Dictionary:
	return mapping.get("visemes", {})


func get_expression_map() -> Dictionary:
	return mapping.get("expressions", {})


func get_smoothing() -> Dictionary:
	return tuning.get("smoothing", {"attack_time": 0.06, "release_time": 0.12})


func get_viseme_bands() -> Dictionary:
	return tuning.get("viseme_bands", {})


func get_noise_gate() -> float:
	return tuning.get("noise_gate", 0.003)


func get_sensitivity() -> float:
	return tuning.get("sensitivity", 8.0)


func get_blink_config() -> Dictionary:
	return tuning.get("blink", {})


func get_openseeface_config() -> Dictionary:
	return tuning.get("openseeface", {"host": "127.0.0.1", "port": 11573})


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Config not found: %s — using defaults" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Cannot open config: %s" % path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	if json.data is Dictionary:
		return json.data
	push_warning("Config root is not a dictionary: %s" % path)
	return {}


func _get_mtime(path: String) -> int:
	if FileAccess.file_exists(path):
		return FileAccess.get_modified_time(path)
	return 0
