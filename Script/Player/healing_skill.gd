extends Node

func active_player() -> Node:
	if get_tree().paused or CheckpointManager.loading:
		return null
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("is_dead") == true or not player.is_physics_processing():
		return null
	return player

func _process(delta: float) -> void:
	if active_player() != null:
		player_data.tick_healing_skill(delta)

func use_skill() -> bool:
	return active_player() != null and player_data.use_healing_skill()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("heal_skill") and not event.is_echo():
		use_skill()
		get_viewport().set_input_as_handled()
