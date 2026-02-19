## HTTP client for Open Source Avatars (opensourceavatars.com).
## Fetches collection index and individual collection data from GitHub-hosted JSON.
## All avatars are CC0 licensed.
class_name AvatarCatalog
extends Node

signal collections_loaded(collections: Array)
signal avatars_loaded(collection_id: String, avatars: Array)
signal catalog_error(message: String)

const BASE_URL := "https://raw.githubusercontent.com/ToxSam/open-source-avatars/main/data/"

## Cached collections list: Array of {id, name, description, license, data_file}
var _collections: Array = []

## Cached avatars per collection: collection_id -> Array of avatar dicts
var _avatar_cache: Dictionary = {}

var _is_loading := false


func fetch_collections():
	if _collections.size() > 0:
		collections_loaded.emit(_collections)
		return
	if _is_loading:
		return
	_is_loading = true

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_collections_received.bind(http))
	var err: int = http.request(BASE_URL + "projects.json")
	if err != OK:
		_is_loading = false
		http.queue_free()
		catalog_error.emit("Failed to start collections request")


func _on_collections_received(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	_is_loading = false

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		catalog_error.emit("Collections fetch failed (HTTP %d)" % code)
		return

	var json := JSON.new()
	var err: int = json.parse(body.get_string_from_utf8())
	if err != OK:
		catalog_error.emit("Collections JSON parse error")
		return

	if not json.data is Array:
		catalog_error.emit("Collections data is not an array")
		return

	_collections.clear()
	for item in json.data:
		if item is Dictionary and item.get("is_public", false):
			_collections.append({
				"id": item.get("id", ""),
				"name": item.get("name", "Unknown"),
				"description": item.get("description", ""),
				"license": item.get("license", ""),
				"data_file": item.get("avatar_data_file", ""),
			})

	collections_loaded.emit(_collections)


func fetch_avatars(collection_id: String):
	# Find the collection's data file
	var data_file := ""
	for c in _collections:
		if c["id"] == collection_id:
			data_file = c["data_file"]
			break
	if data_file == "":
		catalog_error.emit("Collection not found: " + collection_id)
		return

	# Return cached if available
	if _avatar_cache.has(collection_id):
		avatars_loaded.emit(collection_id, _avatar_cache[collection_id])
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_avatars_received.bind(http, collection_id))
	var err: int = http.request(BASE_URL + data_file)
	if err != OK:
		http.queue_free()
		catalog_error.emit("Failed to start avatars request")


func _on_avatars_received(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, collection_id: String):
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		catalog_error.emit("Avatars fetch failed (HTTP %d)" % code)
		return

	var json := JSON.new()
	var err: int = json.parse(body.get_string_from_utf8())
	if err != OK:
		catalog_error.emit("Avatars JSON parse error")
		return

	if not json.data is Array:
		catalog_error.emit("Avatars data is not an array")
		return

	var avatars: Array = []
	for item in json.data:
		if item is Dictionary and item.get("format", "") == "VRM":
			var model_url: String = item.get("model_file_url", "")
			if model_url == "":
				continue
			avatars.append({
				"id": item.get("id", ""),
				"name": item.get("name", "Unknown"),
				"model_url": model_url,
				"thumbnail_url": item.get("thumbnail_url", ""),
				"description": item.get("description", ""),
				"collection_id": collection_id,
			})

	_avatar_cache[collection_id] = avatars
	avatars_loaded.emit(collection_id, avatars)


## Get cached collections (empty if not yet fetched)
func get_collections() -> Array:
	return _collections


## Get cached avatars for a collection (empty if not yet fetched)
func get_cached_avatars(collection_id: String) -> Array:
	return _avatar_cache.get(collection_id, [])
