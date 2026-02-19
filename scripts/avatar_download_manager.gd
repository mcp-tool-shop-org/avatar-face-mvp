## Downloads VRM avatars and thumbnails to user://avatars/.
## Max 1 concurrent VRM download. Streams to disk via HTTPRequest.download_file.
class_name AvatarDownloadManager
extends Node

signal download_started(avatar_name: String)
signal download_progress(avatar_name: String, progress: float)
signal download_completed(avatar_name: String, local_path: String)
signal download_failed(avatar_name: String, error: String)

const AVATARS_DIR := "user://avatars/"
const THUMBS_DIR := "user://avatars/thumbs/"

var _current_download: Dictionary = {}  # {name, url, path, http}
var _queue: Array = []  # Array of {name, url, collection_id}
var _is_downloading := false


func _ready():
	# Ensure directories exist
	if not DirAccess.dir_exists_absolute(AVATARS_DIR):
		DirAccess.make_dir_recursive_absolute(AVATARS_DIR)
	if not DirAccess.dir_exists_absolute(THUMBS_DIR):
		DirAccess.make_dir_recursive_absolute(THUMBS_DIR)


func _process(_delta: float):
	if not _is_downloading or _current_download.is_empty():
		return
	# Update progress from HTTPRequest body_size
	var http: HTTPRequest = _current_download.get("http")
	if http == null:
		return
	var downloaded: int = http.get_downloaded_bytes()
	var total: int = http.get_body_size()
	if total > 0:
		var progress: float = float(downloaded) / float(total)
		download_progress.emit(_current_download["name"], progress)


## Queue a VRM avatar for download
func queue_download(avatar_name: String, model_url: String, collection_id: String):
	# Check if already downloaded
	var file_name: String = _sanitize_filename(avatar_name, collection_id)
	var local_path: String = AVATARS_DIR + file_name
	if FileAccess.file_exists(local_path):
		download_completed.emit(avatar_name, local_path)
		return

	# Check if already in queue or downloading
	if _is_downloading and _current_download.get("name") == avatar_name:
		return
	for item in _queue:
		if item["name"] == avatar_name:
			return

	_queue.append({
		"name": avatar_name,
		"url": model_url,
		"collection_id": collection_id,
	})

	if not _is_downloading:
		_start_next_download()


func _start_next_download():
	if _queue.size() == 0:
		_is_downloading = false
		return

	_is_downloading = true
	var item: Dictionary = _queue.pop_front()
	var file_name: String = _sanitize_filename(item["name"], item["collection_id"])
	var local_path: String = AVATARS_DIR + file_name

	var http := HTTPRequest.new()
	http.download_file = ProjectSettings.globalize_path(local_path)
	http.use_threads = true
	add_child(http)
	http.request_completed.connect(_on_download_completed.bind(http, item["name"], local_path))

	_current_download = {
		"name": item["name"],
		"url": item["url"],
		"path": local_path,
		"http": http,
	}

	download_started.emit(item["name"])

	var err: int = http.request(item["url"])
	if err != OK:
		http.queue_free()
		_current_download.clear()
		download_failed.emit(item["name"], "Request failed to start")
		_start_next_download()


func _on_download_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, avatar_name: String, local_path: String):
	http.queue_free()
	_current_download.clear()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		# Clean up partial file
		if FileAccess.file_exists(local_path):
			DirAccess.remove_absolute(local_path)
		download_failed.emit(avatar_name, "Download failed (HTTP %d)" % code)
	else:
		download_completed.emit(avatar_name, local_path)

	_start_next_download()


## Download a thumbnail image (runs independently, does not block VRM queue)
func download_thumbnail(avatar_id: String, thumbnail_url: String, callback: Callable):
	if thumbnail_url == "":
		return
	var thumb_path: String = THUMBS_DIR + avatar_id + ".png"
	if FileAccess.file_exists(thumb_path):
		var img := Image.new()
		if img.load(thumb_path) == OK:
			var tex := ImageTexture.create_from_image(img)
			callback.call(tex)
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_thumb_received.bind(http, thumb_path, callback))
	var err: int = http.request(thumbnail_url)
	if err != OK:
		http.queue_free()


func _on_thumb_received(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, thumb_path: String, callback: Callable):
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.size() == 0:
		return
	var img := Image.new()
	# Try PNG first, then JPEG
	var err: int = img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		err = img.load_webp_from_buffer(body)
	if err != OK:
		return
	# Save cached thumbnail
	img.save_png(thumb_path)
	var tex := ImageTexture.create_from_image(img)
	callback.call(tex)


## Check if a VRM is already downloaded
func is_downloaded(avatar_name: String, collection_id: String) -> bool:
	var file_name: String = _sanitize_filename(avatar_name, collection_id)
	return FileAccess.file_exists(AVATARS_DIR + file_name)


## Get local path for a downloaded avatar (empty if not downloaded)
func get_local_path(avatar_name: String, collection_id: String) -> String:
	var file_name: String = _sanitize_filename(avatar_name, collection_id)
	var path: String = AVATARS_DIR + file_name
	if FileAccess.file_exists(path):
		return path
	return ""


## Delete a downloaded avatar
func delete_avatar(avatar_name: String, collection_id: String) -> bool:
	var file_name: String = _sanitize_filename(avatar_name, collection_id)
	var path: String = AVATARS_DIR + file_name
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return true
	return false


func _sanitize_filename(avatar_name: String, collection_id: String) -> String:
	var slug: String = avatar_name.to_lower().replace(" ", "-")
	# Remove non-alphanumeric except hyphens
	var clean := ""
	for c in slug:
		if c.is_valid_identifier() or c == "-":
			clean += c
	if collection_id != "":
		return collection_id.to_lower().replace(" ", "-") + "_" + clean + ".vrm"
	return clean + ".vrm"
