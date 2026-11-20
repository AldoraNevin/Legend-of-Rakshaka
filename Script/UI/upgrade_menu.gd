extends Control
const ATLAS := preload("res://Assets/Legend of Rakshaka/Upgrade_menu/Nusantara UI atlas in navy and gold-1.png")
const ICONS := {
	"max_life": preload("res://Assets/Legend of Rakshaka/Upgrade_menu/UP Hp.png"),
	"sword": preload("res://Assets/Legend of Rakshaka/Upgrade_menu/UP Stat.png"),
	"skill_charge": preload("res://Assets/Legend of Rakshaka/Upgrade_menu/UP skill v2.png"),
	"skill_cooldown": preload("res://Assets/Legend of Rakshaka/Upgrade_menu/UP CD.png"),
}
var selected := "max_life"
var owns_pause := false
var panel: Panel
var panel_background: ColorRect
var wallet: Label
var detail: Label
var preview: TextureRect
var buy: Button
var rows: Dictionary = {}

func style(rect: Rect2, margin := 12.0) -> StyleBoxTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = rect
	var result := StyleBoxTexture.new()
	result.texture = texture
	result.set_texture_margin_all(margin)
	result.set_content_margin_all(12)
	return result

func label_at(text: String, rect: Rect2, font_size: int) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_constant_override("line_spacing", 0)
	item.add_theme_constant_override("paragraph_spacing", 0)
	item.add_theme_color_override("font_color", Color("#fff1ca"))
	panel.add_child(item)
	return item

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.06, 0.85)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_background = ColorRect.new()
	panel_background.color = Color("#0d1426")
	add_child(panel_background)
	panel = Panel.new()
	panel.size = Vector2(900, 500)
	panel.add_theme_stylebox_override("panel", style(Rect2(8, 0, 320, 178), 28))
	add_child(panel)
	wallet = label_at("", Rect2(500, 85, 270, 85), 19)
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_at("Tingkatkan kekuatanmu di pelataran suci", Rect2(100, 85, 540, 36), 16)
	var index := 0
	for key in player_data.UPGRADE_DATA:
		var button := Button.new()
		button.position = Vector2(34, 125 + index * 77)
		button.size = Vector2(302, 68)
		button.add_theme_stylebox_override("normal", style(Rect2(8, 187, 165, 40), 10))
		button.add_theme_stylebox_override("hover", style(Rect2(180, 232, 143, 40), 10))
		button.add_theme_stylebox_override("pressed", style(Rect2(180, 232, 143, 40), 10))
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color("#fff1ca"))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 48)
		panel.add_child(button)
		button.pressed.connect(select_upgrade.bind(key))
		rows[key] = button
		index += 1
	var info := Panel.new()
	info.position = Vector2(356, 125)
	info.size = Vector2(510, 284)
	info.add_theme_stylebox_override("panel", style(Rect2(350, 28, 358, 138), 18))
	panel.add_child(info)
	preview = TextureRect.new()
	preview.position = Vector2(382, 144)
	preview.size = Vector2(82, 82)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.add_child(preview)
	detail = label_at("", Rect2(382, 232, 456, 164), 19)
	detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy = Button.new()
	buy.position = Vector2(356, 430)
	buy.size = Vector2(310, 42)
	buy.add_theme_stylebox_override("normal", style(Rect2(278, 401, 127, 39), 10))
	buy.pressed.connect(purchase)
	panel.add_child(buy)
	var back := Button.new()
	back.position = Vector2(682, 430)
	back.size = Vector2(184, 42)
	back.text = "KEMBALI"
	back.add_theme_stylebox_override("normal", style(Rect2(12, 401, 130, 39), 10))
	back.pressed.connect(hide)
	panel.add_child(back)
	visibility_changed.connect(_visibility_changed)
	get_viewport().size_changed.connect(_layout)
	_layout()
	refresh()

func select_upgrade(key: String) -> void:
	selected = key
	refresh()

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var factor := minf((viewport_size.x - 24) / 900.0, (viewport_size.y - 24) / 500.0)
	panel.scale = Vector2.ONE * factor
	panel.position = (viewport_size - Vector2(900, 500) * factor) * 0.5
	panel_background.position = panel.position + Vector2(18, 22) * factor
	panel_background.size = Vector2(864, 456) * factor

func icon(key: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ICONS[key]
	texture.region = Rect2(int(player_data.upgrade_levels[key]) * 181, 0, 181, 183)
	return texture

func open_menu() -> void:
	if not get_tree().paused:
		owns_pause = true
		get_tree().paused = true
	show()
	refresh()

func _visibility_changed() -> void:
	if not visible and owns_pause:
		owns_pause = false
		get_tree().paused = false

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	if not is_instance_valid(wallet):
		return
	wallet.text = "SUKMA  %d" % player_data.coin
	for key in rows:
		var level: int = player_data.upgrade_levels[key]
		rows[key].text = "%s  %d/%d" % [player_data.get_upgrade_name(key), level, player_data.UPGRADE_DATA[key].max_level]
		rows[key].icon = icon(key)
		rows[key].modulate = Color("#7fffea") if key == selected else Color.WHITE
	var level: int = player_data.upgrade_levels[selected]
	var maximum: int = player_data.UPGRADE_DATA[selected].max_level
	preview.texture = icon(selected)
	var current := ""
	var next := ""
	match selected:
		"max_life":
			current = "%d HP" % player_data.max_life
			next = "%d HP" % (player_data.max_life + 5)
		"sword":
			current = "+%d%% damage" % (level * 5)
			next = "+%d%% damage" % ((level + 1) * 5)
		"skill_charge":
			current = "%d charge" % player_data.healing_capacity()
			next = "%d charge" % (player_data.healing_capacity() + 1)
		"skill_cooldown":
			current = "%.1f detik" % player_data.healing_cooldown()
			next = "%.1f detik" % (30 * (1.0 - 0.05 * (level + 1)))
	var cost := player_data.get_upgrade_cost(selected)
	detail.text = "%s\n%s\n\n%s\n%s" % [
		player_data.get_upgrade_name(selected).to_upper(), player_data.UPGRADE_DATA[selected].description,
		current + ("  >  " + next if level < maximum else "  (MAKSIMAL)"),
		"Biaya: %d Sukma | Sisa: %d" % [cost, maxi(0, player_data.coin - cost)] if level < maximum else "Semua peningkatan sudah terbuka."]
	buy.disabled = not player_data.can_upgrade(selected)
	buy.text = "MAKSIMAL" if level >= maximum else ("SUKMA KURANG" if player_data.coin < cost else "TINGKATKAN")

func purchase() -> void:
	if player_data.buy_upgrade(selected):
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			player_data.apply_player_stats(player)
	refresh()
