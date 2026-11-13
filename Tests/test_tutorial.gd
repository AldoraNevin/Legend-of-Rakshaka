extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	change_scene_to_file("res://Levels/tutorial_preview.tscn")
	await process_frame
	await process_frame
	var stage = current_scene
	var room = stage.current_room
	var player = stage.player
	assert(room.step == room.Step.WAITING)
	assert(not room.can_exit())
	stage._enter_graph_door(player, 1)
	assert(stage.node_id == 0)
	assert(room.get_node("GateHint").visible)
	assert("Semar" in room.get_node("GateHint").text)
	assert(not is_instance_valid(room.hostile))
	# Simulate Controls rebinding after the room is already loaded.
	var original_interact = InputMap.action_get_events("ui_interact")
	var original_jump = InputMap.action_get_events("ui_accept")
	var interact_event := InputEventKey.new()
	interact_event.physical_keycode = KEY_F
	InputMap.action_erase_events("ui_interact")
	InputMap.action_add_event("ui_interact", interact_event)
	var jump_event := InputEventKey.new()
	jump_event.physical_keycode = KEY_J
	InputMap.action_erase_events("ui_accept")
	InputMap.action_add_event("ui_accept", jump_event)
	await create_timer(0.3).timeout
	assert(room.get_node("NPC/Prompt").text == "[F] Bicara")
	assert("(F)" in room.objective.text)
	room.interact()
	assert(room.dialogue.visible)
	assert("[F]" in room.get_node("TutorialUI/Dialogue/Margin/Content/Next").text)
	assert(not player.is_physics_processing())
	room.advance_dialogue()
	assert("Tekan J" in room.body_text.text)
	for i in range(room.instructions.size() - 1):
		room.advance_dialogue()
	await process_frame
	assert(room.step == room.Step.PRACTICE)
	assert(is_instance_valid(room.hostile))
	assert(player.is_physics_processing())
	assert("J: lompat" in room.objective.text)
	InputMap.action_erase_events("ui_interact")
	for event in original_interact:
		InputMap.action_add_event("ui_interact", event)
	InputMap.action_erase_events("ui_accept")
	for event in original_jump:
		InputMap.action_add_event("ui_accept", event)
	stage._enter_graph_door(player, 1)
	assert(stage.node_id == 0)
	var first_hostile = room.hostile
	room.interact()
	assert(room.hostile == first_hostile)
	room.hostile.take_damage(100)
	await create_timer(3.0).timeout
	assert(room.step == room.Step.REPORT)
	assert(not room.can_exit())
	stage._enter_graph_door(player, 1)
	assert(stage.node_id == 0)
	assert("Lapor" in room.get_node("GateHint").text)
	room.interact()
	assert(room.step == room.Step.REPORT_DIALOGUE)
	assert(room.dialogue.visible)
	assert(room.body_text.text == room.report_text)
	assert(not player.is_physics_processing())
	assert(not room.can_exit())
	room.advance_dialogue()
	assert(room.can_exit())
	assert(not room.dialogue.visible)
	assert(player.is_physics_processing())
	stage._enter_graph_door(player, 1)
	assert(stage.node_id == 1)
	await process_frame
	await process_frame
	assert(stage.current_room != room)
	print("PASS: tutorial controls, dialogue, hostile defeat, mandatory report, and gate transition.")
	quit()

