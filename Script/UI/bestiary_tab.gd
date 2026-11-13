@tool
extends Control
## Coordinates use the 1080 x 608 reference book and scale together on resize.
signal category_requested(artifacts: bool)
signal close_requested
@export var artifact_mode := false
@export_range(0, 99) var preview_entry := 0
@export var preview_all_when_run_alone := true
var preview_elapsed := 0.0
var cards: Array[Button] = []
var preview_mode := false

@export var auto_fit_book := true
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

const PAGE_SIZE := 12

@warning_ignore("integer_division")
func _page_of(index: int) -> int:
	return index / PAGE_SIZE

var entries: Array = []
var filtered: Array = []
var selected: Dictionary = {}
var page := 0
var history_mode := false

func _ready() -> void:
	design_size = book.size
	design_position = book.position
	if Engine.is_editor_hint():
		return
	enemy_tab.pressed.connect(_request_category.bind(false))
	artifact_tab.pressed.connect(_request_category.bind(true))
	close_button.pressed.connect(_close_tab)
	description_tab.pressed.connect(_set_detail.bind(false))
	history_tab.pressed.connect(_set_detail.bind(true))
	previous.pressed.connect(_turn.bind(-1))
	next.pressed.connect(_turn.bind(1))
	search.text_changed.connect(func(_value: String): _filter())
	region.item_selected.connect(func(_index: int): _filter())
	discovered.toggled.connect(func(_value: bool): _filter())
	for card in grid.get_children():
		cards.append(card)
		entries.append(card.get_entry())
		card.button_group = card_group
		card.pressed.connect(_select.bind(entries.back()))
	resized.connect(_fit)
	_fit()
	# current_scene may not be assigned yet during _ready (F6/load_scene).
	_initialize_content.call_deferred()

func _initialize_content() -> void:
	if get_tree().current_scene == self:
		refresh_entries(preview_all_when_run_alone)
	elif entries.size() > 0 and filtered.is_empty():
		refresh_entries(preview_mode)

func _request_category(artifacts: bool) -> void:
	if get_tree().current_scene == self:
		if artifacts != artifact_mode:
			get_tree().change_scene_to_file.call_deferred("res://Scenes/Interactables/bestiary_%s_tab.tscn" % ("artifacts" if artifacts else "enemies"))
	else:
		category_requested.emit(artifacts)

func _close_tab() -> void:
	if get_tree().current_scene == self:
		hide()
	else:
		close_requested.emit()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	preview_elapsed += delta
	if preview_elapsed < 0.3:
		return
	preview_elapsed = 0.0
	var nodes := grid.get_children()
	if nodes.is_empty():
		return
	var selected_index := clampi(preview_entry, 0, nodes.size() - 1)
	var card = nodes[selected_index]
	var entry: Dictionary = card.get_entry()
	entry["is_unlocked"] = true
	_select(entry)
	progress.text = "%d / %d" % [nodes.size(), nodes.size()]
	page_label.text = "%d / %d" % [_page_of(selected_index) + 1, maxi(1, ceili(nodes.size() / 12.0))]
	previous.disabled = selected_index < 12
	next.disabled = (_page_of(selected_index) + 1) * 12 >= nodes.size()
	empty_label.hide()
	for index in range(nodes.size()):
		nodes[index].visible = _page_of(index) == _page_of(selected_index)
		nodes[index].set_pressed_no_signal(index == selected_index)
	enemy_tab.set_pressed_no_signal(not artifact_mode)
	artifact_tab.set_pressed_no_signal(artifact_mode)

func refresh_entries(reveal_all: bool = false) -> void:
	preview_mode = reveal_all
	if not preview_mode:
		player_data.init_system()
	var found: Array = player_data.discovered_artifacts if artifact_mode else player_data.discovered_enemies
	region.clear()
	region.add_item("Semua wilayah")
	var regions: Array[String] = []
	var unlocked := 0
	for entry in entries:
		# Older saves store display names; keep unlocks when authors rename a card.
		var saved_name: String = entry.name
		for section in (["artifacts"] if artifact_mode else ["enemies", "bosses"]):
			for original in player_data.bestiary_master.get(section, []):
				if original.get("entity_id", "") == entry.entity_id:
					saved_name = str(original.get("name", saved_name))
		entry["is_unlocked"] = preview_mode or entry.entity_id in found or saved_name in found or entry.name in found
		if entry.is_unlocked:
			unlocked += 1
		var place: String = entry.get("region", "Nusantara")
		if place not in regions:
			regions.append(place)
	regions.sort()
	for place in regions:
		region.add_item(place)
	progress.text = "%d / %d" % [unlocked, entries.size()]
	enemy_tab.set_pressed_no_signal(not artifact_mode)
	artifact_tab.set_pressed_no_signal(artifact_mode)
	if preview_mode:
		search.text = ""
		discovered.set_pressed_no_signal(false)
	_filter()
	# The catalog and standalone tabs share the exact same preview selection.
	if preview_mode and not entries.is_empty():
		var index := clampi(preview_entry, 0, entries.size() - 1)
		page = _page_of(index)
		_refresh_page()
		cards[index].set_pressed_no_signal(true)
		_select(entries[index])

func _fit() -> void:
	if book == null or not auto_fit_book:
		return
	var factor := minf(size.x / design_size.x, size.y / design_size.y)
	book.scale = Vector2.ONE * factor
	book.position = (size - design_size * factor) / 2.0 + design_position * factor

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
	if entry.get("portrait") != null:
		return entry.portrait
	return fallback_portrait

func _turn(direction: int) -> void:
	page = clampi(page + direction, 0, maxi(0, ceili(filtered.size() / 12.0) - 1))
	_refresh_page()

func _refresh_page() -> void:
	page_label.text = "%d / %d" % [page + 1, maxi(1, ceili(filtered.size() / 12.0))]
	previous.disabled = page == 0
	next.disabled = (page + 1) * 12 >= filtered.size()
	empty_label.visible = filtered.is_empty()
	for index in range(cards.size()):
		var card := cards[index]
		var entry: Dictionary = entries[index]
		var filtered_index := filtered.find(entry)
		card.visible = filtered_index >= page * 12 and filtered_index < (page + 1) * 12
		card.set_pressed_no_signal(false)
		card.configure(entry, _portrait(entry), artifact_mode)
	if not filtered.is_empty():
		var entry: Dictionary = filtered[page * 12]
		cards[entries.find(entry)].set_pressed_no_signal(true)
		_select(entry)
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
		if not artifact_mode and int(selected.get("hp", 0)) > 0:
			details.add_text("\n\nHP: %s     Serangan: %s" % [selected.get("hp", 0), selected.get("attack", 0)])
	details.scroll_to_line(0)
