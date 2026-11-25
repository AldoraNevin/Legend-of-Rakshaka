extends CanvasLayer
const ATLAS := preload("res://Legend of Rakshaka/UI HUD/Legend of Rakshaka Loading UI Atlas-4.png")
var busy := false
var screen: Control
var caption: Label
var bar: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	screen = Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var art := preload("res://Script/UI/room_loading_art.gd").new()
	screen.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	title.name = "Title"
	title.text = "LEGEND OF RAKSHAKA"
	title.add_theme_font_override("font", preload("res://Legend of Rakshaka/Fonts/PixelifySans/PixelifySansBold.tres"))
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#fff4d4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen.add_child(title)
	caption = Label.new()
	caption.text = "MEMUAT..."
	caption.add_theme_font_override("font", preload("res://Legend of Rakshaka/Fonts/PixelifySans/PixelifySans.ttf"))
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color("#fff4d4"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen.add_child(caption)
	bar = preload("res://Script/UI/room_loading_bar.gd").new()
	screen.add_child(bar)
	var tip := Label.new()
	tip.name = "Tip"
	tip.text = "Perhatikan gerakan musuh sebelum menyerang."
	tip.add_theme_font_override("font", preload("res://Legend of Rakshaka/Fonts/PixelifySans/PixelifySans.ttf"))
	tip.add_theme_font_size_override("font_size", 15)
	tip.add_theme_color_override("font_color", Color("#fff4d4"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen.add_child(tip)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()

func begin(title: String) -> void:
	busy = true
	caption.text = "MEMUAT..."
	caption.tooltip_text = title
	bar.value = 12
	show()
	# Yield before synchronous generation so the loading screen is rendered first.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.15, true).timeout
	bar.value = 35
	await get_tree().process_frame

func finish() -> void:
	bar.value = 100
	await get_tree().create_timer(0.2, true).timeout
	hide()
	busy = false

func change_room(operation: Callable, title := "Memuat ruangan...") -> void:
	if busy:
		return
	var was_paused := get_tree().paused
	get_tree().paused = true
	await begin(title)
	if operation.is_valid():
		operation.call()
	await get_tree().process_frame
	await finish()
	get_tree().paused = was_paused

func change_scene(path: String) -> int:
	if busy:
		return ERR_BUSY
	await begin("Memuat perjalanan...")
	var error := get_tree().change_scene_to_file(path)
	if error == OK:
		await get_tree().scene_changed
	await finish()
	return error


func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var factor := minf(viewport_size.x / 1080.0, viewport_size.y / 608.0)
	var origin := (viewport_size - Vector2(1080, 608) * factor) * 0.5
	var controls := [screen.get_node("Title"), bar, caption, screen.get_node("Tip")]
	var rects := [Rect2(270, 307, 540, 34), Rect2(315, 397, 450, 34), Rect2(315, 440, 450, 30), Rect2(355, 518, 370, 30)]
	for i in range(controls.size()):
		controls[i].scale = Vector2.ONE * factor
		controls[i].position = origin + rects[i].position * factor
		controls[i].size = rects[i].size
