extends "res://Script/Interactables/coastal_treasure.gd"
## Artifact branches unlock the existing artifact catalog; treasure gives coins.
@export_enum("treasure", "artifact") var reward_kind := "treasure"
@export var artifact_name := "Daun Kelor"

func _ready() -> void:
	super._ready()
	add_to_group("level_rewards")
	if reward_kind == "artifact":
		prompt.text = "[E] Ambil artefak"
		prompt.modulate = Color(0.65, 0.85, 1.0)

func _draw() -> void:
	if reward_kind == "treasure":
		super._draw()
		return
	draw_rect(Rect2(-16, 4, 32, 12), Color(0.25, 0.33, 0.4))
	draw_rect(Rect2(-20, 2, 40, 4), Color(0.65, 0.72, 0.78))
	if not opened:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -27), Vector2(9, -16), Vector2(0, -5), Vector2(-9, -16)]), Color(0.35, 0.85, 1.0))
		draw_circle(Vector2(0, -16), 3, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
	if reward_kind != "artifact":
		super._unhandled_input(event)
		return
	if opened or not event.is_action_pressed("ui_interact") or event.is_echo():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or absf(player.global_position.x - global_position.x) > 42 or absf(player.global_position.y - global_position.y) > 32:
		return
	opened = true
	player_data.discover_artifact(artifact_name)
	if player.has_method("refresh_jump_ability"):
		player.refresh_jump_ability()
	prompt.text = artifact_name + " ditemukan"
	queue_redraw()
	get_viewport().set_input_as_handled()
