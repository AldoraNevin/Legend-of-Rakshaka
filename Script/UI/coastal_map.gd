extends CanvasLayer
const VIEW = preload("res://Script/UI/coastal_map_view.gd")
var room: Node2D
var view: Control
var hint: Label
var owns_pause := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = VIEW.new()
	view.room = room
	add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.hide()
	hint = Label.new()
	hint.text = "[M] Peta coastal"
	hint.position = Vector2(16, 64)
	hint.add_theme_font_size_override("font_size", 14)
	add_child(hint)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M or event.keycode == KEY_M:
			if owns_pause:
				close_map()
			elif not get_tree().paused:
				owns_pause = true
				view.show()
				hint.hide()
				view.queue_redraw()
				get_tree().paused = true
			get_viewport().set_input_as_handled()
			return
		if owns_pause and event.keycode == KEY_ESCAPE:
			close_map()
			get_viewport().set_input_as_handled()
			return
	if owns_pause:
		get_viewport().set_input_as_handled()

func close_map() -> void:
	view.hide()
	hint.show()
	if owns_pause:
		owns_pause = false
		get_tree().paused = false

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false
