## Loads and provides access to JSON config files.
## Supports hot-reload by checking file modification time.
class_name ConfigLoader
extends RefCounted

const MAPPING_PATH := "res://config/mapping.json"
const TUNING_PATH := "res://config/tuning.json"

var mapping: Dictionary = {}
var tuning: Dictionary = {}

var _mapping_mtime := 0
var _tuning_mtime := 0


func _init():
	reload()


func reload():
	mapping = _load_json(MAPPING_PATH)
	tuning = _load_json(TUNING_PATH)


## Check if files changed and reload if so. Call periodically (not every frame).
func check_hot_reload() -> bool:
	var changed := false
	var m_time := _get_mtime(MAPPING_PATH)
	if m_time != _mapping_mtime:
		_mapping_mtime = m_time
		mapping = _load_json(MAPPING_PATH)
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
