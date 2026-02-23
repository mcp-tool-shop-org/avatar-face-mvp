## Avatar Library browser panel.
## Installed tab: shows bundled + downloaded avatars.
## Browse tab: fetches remote catalog from Open Source Avatars, allows downloading.
extends PanelContainer

signal avatar_load_requested(path: String)

@onready var close_button: Button = %LibCloseButton
@onready var installed_tab: ScrollContainer = %InstalledTab
@onready var browse_tab: ScrollContainer = %BrowseTab
@onready var installed_grid: GridContainer = %InstalledGrid
@onready var browse_grid: GridContainer = %BrowseGrid
@onready var collection_picker: OptionButton = %CollectionPicker
@onready var tab_installed_btn: Button = %TabInstalledBtn
@onready var tab_browse_btn: Button = %TabBrowseBtn
@onready var lib_status: Label = %LibStatus

var _catalog: AvatarCatalog = null
var _download_mgr: AvatarDownloadManager = null
var _main_node: Node3D = null

## Track which tab is active
var _active_tab := 0  # 0=installed, 1=browse


func setup(catalog: AvatarCatalog, download_mgr: AvatarDownloadManager, main_node: Node3D):
	_catalog = catalog
	_download_mgr = download_mgr
	_main_node = main_node

	_catalog.collections_loaded.connect(_on_collections_loaded)
	_catalog.avatars_loaded.connect(_on_avatars_loaded)
	_catalog.catalog_error.connect(_on_catalog_error)
	_download_mgr.download_started.connect(_on_download_started)
	_download_mgr.download_completed.connect(_on_download_completed)
	_download_mgr.download_failed.connect(_on_download_failed)


func _ready():
	close_button.pressed.connect(func(): visible = false)
	tab_installed_btn.pressed.connect(func(): _switch_tab(0))
	tab_browse_btn.pressed.connect(func(): _switch_tab(1))
	collection_picker.item_selected.connect(_on_collection_selected)
	_switch_tab(0)


func _switch_tab(tab: int):
	_active_tab = tab
	installed_tab.visible = (tab == 0)
	browse_tab.visible = (tab == 1)
	tab_installed_btn.disabled = (tab == 0)
	tab_browse_btn.disabled = (tab == 1)

	if tab == 0:
		_refresh_installed()
	elif tab == 1:
		if _catalog and _catalog.get_collections().size() == 0:
			lib_status.text = "Loading collections..."
			_catalog.fetch_collections()
		else:
			_refresh_browse_current()


func show_library():
	visible = true
	_refresh_installed()


func _refresh_installed():
	# Clear grid
	for child in installed_grid.get_children():
		child.queue_free()

	if _main_node == null:
		return

	var names: PackedStringArray = _main_node._avatar_names
	var paths: PackedStringArray = _main_node._avatar_paths
	var count := 0

	for i in names.size():
		var card := _create_installed_card(names[i], paths[i])
		installed_grid.add_child(card)
		count += 1

	lib_status.text = "%d avatar(s) installed" % count


func _create_installed_card(display_name: String, path: String) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(120, 80)

	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(label)

	var source_label := Label.new()
	if path.begins_with("user://"):
		source_label.text = "[downloaded]"
	else:
		source_label.text = "[bundled]"
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_label.add_theme_font_size_override("font_size", 10)
	card.add_child(source_label)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(func(): avatar_load_requested.emit(path))
	card.add_child(load_btn)

	return card


## Browse tab: collections loaded
func _on_collections_loaded(collections: Array):
	collection_picker.clear()
	for c in collections:
		collection_picker.add_item(c["name"])
	if collections.size() > 0:
		lib_status.text = "%d collection(s) found" % collections.size()
		collection_picker.selected = 0
		_on_collection_selected(0)
	else:
		lib_status.text = "No collections found"


func _on_collection_selected(idx: int):
	var collections: Array = _catalog.get_collections()
	if idx < 0 or idx >= collections.size():
		return
	var collection_id: String = collections[idx]["id"]

	# Check cache first
	var cached: Array = _catalog.get_cached_avatars(collection_id)
	if cached.size() > 0:
		_populate_browse_grid(cached)
	else:
		lib_status.text = "Loading avatars..."
		_catalog.fetch_avatars(collection_id)


func _on_avatars_loaded(collection_id: String, avatars: Array):
	_populate_browse_grid(avatars)
	lib_status.text = "%d avatar(s) in collection" % avatars.size()


func _populate_browse_grid(avatars: Array):
	for child in browse_grid.get_children():
		child.queue_free()

	for avatar in avatars:
		var card := _create_browse_card(avatar)
		browse_grid.add_child(card)


func _create_browse_card(avatar: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(120, 100)

	# Thumbnail placeholder
	var thumb_rect := TextureRect.new()
	thumb_rect.custom_minimum_size = Vector2(100, 60)
	thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	card.add_child(thumb_rect)

	# Request thumbnail
	if _download_mgr and avatar.get("thumbnail_url", "") != "":
		_download_mgr.download_thumbnail(
			avatar.get("id", ""),
			avatar["thumbnail_url"],
			func(tex: Texture2D): thumb_rect.texture = tex
		)

	var name_label := Label.new()
	name_label.text = avatar.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(name_label)

	var avatar_name: String = avatar.get("name", "")
	var collection_id: String = avatar.get("collection_id", "")
	var model_url: String = avatar.get("model_url", "")

	# Check if already downloaded
	if _download_mgr and _download_mgr.is_downloaded(avatar_name, collection_id):
		var load_btn := Button.new()
		load_btn.text = "Load"
		var local_path: String = _download_mgr.get_local_path(avatar_name, collection_id)
		load_btn.pressed.connect(func(): avatar_load_requested.emit(local_path))
		card.add_child(load_btn)
	else:
		var dl_btn := Button.new()
		dl_btn.text = "Download"
		dl_btn.name = "DLBtn_" + avatar.get("id", "").left(8)
		dl_btn.pressed.connect(
			func():
				dl_btn.text = "Queued..."
				dl_btn.disabled = true
				_download_mgr.queue_download(avatar_name, model_url, collection_id)
		)
		card.add_child(dl_btn)

	return card


func _on_catalog_error(message: String):
	lib_status.text = "Error: " + message


func _on_download_started(avatar_name: String):
	lib_status.text = "Downloading: " + avatar_name + "..."


func _on_download_completed(avatar_name: String, local_path: String):
	lib_status.text = "Downloaded: " + avatar_name
	# Refresh both lists
	if _main_node:
		_main_node.refresh_avatar_list()
	if _active_tab == 0:
		_refresh_installed()
	else:
		_refresh_browse_current()


func _on_download_failed(avatar_name: String, error: String):
	lib_status.text = "Failed: " + avatar_name + " — " + error


func _refresh_browse_current():
	if collection_picker.selected < 0:
		return
	_on_collection_selected(collection_picker.selected)
