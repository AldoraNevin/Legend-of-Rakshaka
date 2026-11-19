extends Node2D
## Optional reward; deliberately independent from combat completion.
const REWARD := 5
const CHEST_TEXTURE := preload("res://Assets/Legend of Rakshaka/Environment/Decoration/Peti 2 frame.png")
var opened := false
var prompt: Label

func _ready() -> void:
	prompt = Label.new()
	prompt.position = Vector2(-64, -48)
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.text = "[E] Buka peti"
	prompt.modulate = Color(1.0, 0.8, 0.35)
	add_child(prompt)

func _draw() -> void:
	# Both frames share the same ground line; opening only raises the lid.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	draw_texture_rect_region(CHEST_TEXTURE, Rect2(-24, -30, 48, 46),
		Rect2(104 if opened else 0, 40, 104, 100))

func _unhandled_input(event: InputEvent) -> void:
	if opened or not event.is_action_pressed("ui_interact") or event.is_echo():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or absf(player.global_position.x - global_position.x) > 42 or absf(player.global_position.y - global_position.y) > 32:
		return
	opened = true
	player_data.add_gold(REWARD)
	prompt.text = "+%d koin - peti kosong" % REWARD
	queue_redraw()
	get_viewport().set_input_as_handled()
