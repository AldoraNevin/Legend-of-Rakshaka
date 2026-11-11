extends Control
## Coordinates use the 1080 x 608 reference book and scale together on resize.
signal closed

@export var auto_fit_book := true
@export var portrait_overrides: Dictionary[String, Texture2D] = {}
@export var locked_portrait: Texture2D
@export var fallback_portrait: Texture2D
var design_size := Vector2(1080, 608)
var design_position := Vector2.ZERO
var card_group := ButtonGroup.new()


@onready var book: Control = $Book
@onready var grid: GridContainer = $Book/EntryGrid
@onready var search: LineEdit = $Book/SearchInput
@onready var region: OptionButton = $Book/RegionFilter
@onready var discovered: CheckBox = $Book/DiscoveredOnly
@onready var progress: Label = $Book/ProgressLabel
@onready var page_label: Label = $Book/PageLabel
@onready var empty_label: Label = $Book/EmptyLabel
@onready var title_label: Label = $Book/EntryTitle
@onready var region_label: Label = $Book/EntryRegion
@onready var category_label: Label = $Book/EntryCategory
@onready var portrait: TextureRect = $Book/Portrait
@onready var details: RichTextLabel = $Book/DetailText
@onready var previous: Button = $Book/PreviousButton
@onready var next: Button = $Book/NextButton
@onready var enemy_tab: Button = $Book/EnemyTab
@onready var artifact_tab: Button = $Book/ArtifactTab
@onready var description_tab: Button = $Book/DescriptionTab
@onready var history_tab: Button = $Book/HistoryTab
@onready var close_button: Button = $Book/CloseButton
var entries: Array = []
var filtered: Array = []
var selected: Dictionary = {}
var page := 0
var artifact_mode := false
var history_mode := false
var was_paused := false
var previous_focus: Control

func _ready() -> void:
	# The scene owns all visuals. Only connect behavior here.
	design_size = book.size
	design_position = book.position
	enemy_tab.pressed.connect(_set_category.bind(false))
	artifact_tab.pressed.connect(_set_category.bind(true))
	description_tab.pressed.connect(_set_detail.bind(false))
	history_tab.pressed.connect(_set_detail.bind(true))
	previous.pressed.connect(_turn.bind(-1))
	next.pressed.connect(_turn.bind(1))
	close_button.pressed.connect(close_book)
	search.text_changed.connect(func(_value: String): _filter())
	region.item_selected.connect(func(_index: int): _filter())
	discovered.toggled.connect(func(_value: bool): _filter())
	for index in range(grid.get_child_count()):
		var card: Button = grid.get_child(index)
		card.button_group = card_group
		card.pressed.connect(_select_slot.bind(index))
	resized.connect(_fit)
	_fit()
	hide()
	# F6 opens the standalone catalogue; lobby instances wait for interaction.
	if get_tree().current_scene == self:
		open_book.call_deferred()

func _select_slot(slot: int) -> void:
	var index := page * grid.get_child_count() + slot
	if index < filtered.size():
		_select(filtered[index])

func _fit() -> void:
	if book == null or not auto_fit_book:
		return
	var factor := minf(size.x / design_size.x, size.y / design_size.y)
	book.scale = Vector2.ONE * factor
	book.position = (size - design_size * factor) / 2.0 + design_position * factor

func open_book(show_artifacts: bool = false) -> void:
	if visible:
		return
	player_data.init_system()
	player_data.sync_bestiary_status()
	previous_focus = get_viewport().gui_get_focus_owner()
	was_paused = get_tree().paused
	get_tree().paused = true
	search.text = ""
	discovered.set_pressed_no_signal(false)
	show()
	_set_category(show_artifacts)
	close_button.grab_focus()

func close_book() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = was_paused
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	closed.emit()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = was_paused

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_book()
		get_viewport().set_input_as_handled()

func _set_category(value: bool) -> void:
	artifact_mode = value
	enemy_tab.set_pressed_no_signal(not value)
	artifact_tab.set_pressed_no_signal(value)
	entries = []
	if value:
		entries.append_array(player_data.bestiary_master.get("artifacts", []))
	else:
		entries.append_array(player_data.bestiary_master.get("enemies", []))
		entries.append_array(player_data.bestiary_master.get("bosses", []))
	region.clear()
	region.add_item("Semua wilayah")
	var regions: Array[String] = []
	var unlocked := 0
	for entry in entries:
		var place: String = entry.get("region", "Nusantara")
		if place not in regions:
			regions.append(place)
		if entry.get("is_unlocked", false):
			unlocked += 1
	regions.sort()
	for place in regions:
		region.add_item(place)
	progress.text = "%d / %d" % [unlocked, entries.size()]
	_filter()

func _filter() -> void:
	filtered = []
	var query := search.text.strip_edges().to_lower()
	for entry in entries:
		var unlocked: bool = entry.get("is_unlocked", false)
		if discovered.button_pressed and not unlocked:
			continue
		# Artifact identities match the lobby catalogue; enemy identities stay locked.
		var identity_visible: bool = unlocked or artifact_mode
		if not query.is_empty() and (not identity_visible or not str(entry.get("name", "")).to_lower().contains(query)):
			continue
		if region.selected > 0 and (not identity_visible or entry.get("region", "Nusantara") != region.get_item_text(region.selected)):
			continue
		filtered.append(entry)
	page = 0
	_refresh_page()

func _portrait(entry: Dictionary) -> Texture2D:
	if not artifact_mode and not entry.get("is_unlocked", false):
		return locked_portrait
	var id: String = entry.get("entity_id", "")
	if portrait_overrides.has(id):
		return portrait_overrides[id]
	var path: String = entry.get("image_path", "")
	if not path.is_empty() and not "sheet" in path.to_lower() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return fallback_portrait

func _turn(direction: int) -> void:
	page = clampi(page + direction, 0, maxi(0, ceili(float(filtered.size()) / grid.get_child_count()) - 1))
	_refresh_page()

func _refresh_page() -> void:
	var slots := grid.get_child_count()
	page_label.text = "%d / %d" % [page + 1, maxi(1, ceili(float(filtered.size()) / slots))]
	previous.disabled = page == 0
	next.disabled = (page + 1) * slots >= filtered.size()
	empty_label.visible = filtered.is_empty()
	for slot in range(slots):
		var card = grid.get_child(slot)
		var index := page * slots + slot
		card.visible = index < filtered.size()
		card.set_pressed_no_signal(false)
		if card.visible:
			var entry: Dictionary = filtered[index]
			card.configure(entry, _portrait(entry), artifact_mode)
	if not filtered.is_empty():
		grid.get_child(0).set_pressed_no_signal(true)
		_select(filtered[page * slots])
	else:
		_select({})

func _select(entry: Dictionary) -> void:
	selected = entry
	var unlocked: bool = entry.get("is_unlocked", false) or artifact_mode
	title_label.text = str(entry.get("name", "")).to_upper() if unlocked else "BELUM DITEMUKAN"
	if entry.is_empty():
		title_label.text = "CATATAN KOSONG"
	portrait.texture = _portrait(entry) if not entry.is_empty() else null
	region_label.text = str(entry.get("region", "Nusantara")) if unlocked else "Wilayah belum diketahui"
	region_label.tooltip_text = region_label.text
	var category: String = entry.get("category", "")
	category_label.text = {"Melee": "Jarak dekat", "Ranged": "Jarak jauh"}.get(category, category) if unlocked else "???"
	_set_detail(false)

func _set_detail(value: bool) -> void:
	history_mode = value
	description_tab.set_pressed_no_signal(not value)
	history_tab.set_pressed_no_signal(value)
	details.clear()
	if selected.is_empty():
		details.add_text("Tidak ada catatan yang cocok. Ubah pencarian atau filter wilayah.")
	elif not selected.get("is_unlocked", false):
		details.add_text("Catatan ini masih terkunci.\n\n" + ("Temukan artefak dalam perjalanan untuk membuka kisahnya." if artifact_mode else "Kalahkan musuh dalam perjalanan untuk membuka catatan mitologinya."))
	elif value:
		details.add_text(str(selected.get("history", selected.get("lore_text", "Catatan sejarah belum tersedia."))))
	else:
		details.add_text(str(selected.get("description", selected.get("lore_text", ""))))
		for field in ["attack_pattern", "tactics"]:
			if not str(selected.get(field, "")).is_empty():
				details.push_color(Color("006267"))
				details.add_text("\n\n" + ("POLA SERANG" if field == "attack_pattern" else "TAKTIK") + "\n")
				details.pop()
				details.add_text(str(selected[field]))
		if selected.has("hp"):
			details.add_text("\n\nHP: %s     Serangan: %s" % [selected.get("hp", 0), selected.get("attack", 0)])
	details.scroll_to_line(0)


