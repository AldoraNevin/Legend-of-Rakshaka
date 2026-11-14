extends Node2D
## Optional reward; deliberately independent from combat completion.
const REWARD := 5
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
	draw_rect(Rect2(-18, -8, 36, 24), Color(0.35, 0.19, 0.08))
	draw_rect(Rect2(-18, -8, 36, 24), Color(1.0, 0.75, 0.25), false, 2)
	draw_rect(Rect2(-20, -20 if opened else -12, 40, 6), Color(0.9, 0.62, 0.16))
	if not opened:
		draw_rect(Rect2(-3, -5, 6, 9), Color(1.0, 0.9, 0.45))

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
