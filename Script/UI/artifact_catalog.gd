extends Control
## Book UI uses the master catalogue; image_path must reference a single illustration.
signal closed

const INK := Color("493322")
const PAPER := Color("ead8b0")
var entries: Array = []
var page := 0
var selected := 0
var was_paused := false
var grid: GridContainer
var picture: TextureRect
var title_label: Label
var category_label: Label
var status_label: Label
var description: Label
var page_label: Label
var progress_label: Label
var previous: Button
var next: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	hide()

func _style(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(Color("dfc695"), Color("a8814b")))
	button.add_theme_stylebox_override("hover", _style(Color("f7e8c8"), Color("926637"), 2))
	button.add_theme_stylebox_override("pressed", _style(Color("c9ab73"), INK, 2))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("835522"), 2))
	return button

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.025, 0.02, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var cover := PanelContainer.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.offset_left = 24
	cover.offset_top = 24
	cover.offset_right = -24
	cover.offset_bottom = -24
	cover.add_theme_stylebox_override("panel", _style(Color("513325"), Color("b18a50"), 3))
	add_child(cover)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	cover.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var heading := _label("PUSAKA NUSANTARA  /  Katalog Artefak", 22)
	heading.add_theme_color_override("font_color", Color("f5dfb3"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := _button("Tutup  [Esc]")
	close.pressed.connect(close_book)
	header.add_child(close)
	var pages := HBoxContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation", 6)
	outer.add_child(pages)
	var columns: Array[VBoxContainer] = []
	for i in range(2):
		var paper := PanelContainer.new()
		paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		paper.add_theme_stylebox_override("panel", _style(PAPER if i == 0 else Color("f2e4c4"), Color("ba9b65")))
		pages.add_child(paper)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		paper.add_child(column)
		columns.append(column)
	progress_label = _label("")
	columns[0].add_child(progress_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns[0].add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var navigation := HBoxContainer.new()
	columns[0].add_child(navigation)
	previous = _button("< Sebelumnya")
	previous.pressed.connect(_turn.bind(-1))
	navigation.add_child(previous)
	page_label = _label("")
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(page_label)
	next = _button("Berikutnya >")
	next.pressed.connect(_turn.bind(1))
	navigation.add_child(next)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns[1].add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail)
	category_label = _label("", 14)
	detail.add_child(category_label)
	title_label = _label("", 26)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(title_label)
	picture = TextureRect.new()
	picture.custom_minimum_size = Vector2(0, 210)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail.add_child(picture)
	status_label = _label("", 16)
	detail.add_child(status_label)
	description = _label("", 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(description)
	var foot := _label("Pilih pusaka untuk membaca catatannya.  |  Temukan artefak untuk membuka kisahnya.", 14)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_theme_color_override("font_color", Color("e6cda0"))
	outer.add_child(foot)

func open_book() -> void:
	if visible:
		return
	player_data.init_system()
	player_data.sync_bestiary_status()
	entries = player_data.bestiary_master.get("artifacts", [])
	was_paused = get_tree().paused
	get_tree().paused = true
	show()
	page = 0
	_refresh_page()

func close_book() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = was_paused
	closed.emit()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = was_paused

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_book()
		get_viewport().set_input_as_handled()

func _texture(entry: Dictionary) -> Texture2D:
	var path: String = entry.get("image_path", "")
	if path.is_empty() or "sheet" in path.to_lower() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _turn(direction: int) -> void:
	page = clampi(page + direction, 0, maxi(0, ceili(entries.size() / 6.0) - 1))
	_refresh_page()

func _refresh_page() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var count := 0
	for entry in entries:
		if entry.get("is_unlocked", false):
			count += 1
	progress_label.text = "KOLEKSI PUSAKA  /  %d dari %d ditemukan" % [count, entries.size()]
	page_label.text = "%d / %d" % [page + 1, maxi(1, ceili(entries.size() / 6.0))]
	previous.disabled = page == 0
	next.disabled = (page + 1) * 6 >= entries.size()
	for index in range(page * 6, mini((page + 1) * 6, entries.size())):
		var entry: Dictionary = entries[index]
		var button := _button("")
		button.custom_minimum_size = Vector2(0, 138)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = entry.get("name", "")
		grid.add_child(button)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 8
		content.offset_right = -8
		content.offset_top = 8
		content.offset_bottom = -8
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		var icon := TextureRect.new()
		icon.texture = _texture(entry)
		icon.custom_minimum_size.y = 72
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		var caption := _label(entry.get("name", ""), 14)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(caption)
		var state := _label("Ditemukan" if entry.get("is_unlocked", false) else "Belum ditemukan", 12)
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(state)
		button.pressed.connect(_select.bind(index))
	if not entries.is_empty():
		_select(page * 6)
		grid.get_child(0).grab_focus()
	else:
		title_label.text = "Katalog masih kosong"

func _select(index: int) -> void:
	selected = index
	var entry: Dictionary = entries[index]
	title_label.text = entry.get("name", "")
	category_label.text = "CATATAN %02d  /  %s" % [index + 1, entry.get("category", "Pusaka").to_upper()]
	picture.texture = _texture(entry)
	status_label.text = "Ditemukan" if entry.get("is_unlocked", false) else "Belum ditemukan"
	if picture.texture == null:
		status_label.text += "  /  Ilustrasi belum tersedia"
	description.text = entry.get("lore_text", "") if entry.get("is_unlocked", false) else "Catatan pusaka ini belum terbuka. Temukan artefak dalam perjalanan untuk mengungkap kisah dan khasiatnya."
