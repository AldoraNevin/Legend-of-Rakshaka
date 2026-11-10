extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	assert(room.prepare(42))
	root.add_child(room)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	root.add_child(player)
	var chest = room.get_node("OptionalTreasure")
	var initial_coins := player_data.coin
	var action := InputEventAction.new()
	action.action = "ui_interact"
	action.pressed = true
	player.global_position = chest.global_position + Vector2(0, 128)
	chest._unhandled_input(action)
	assert(not chest.opened) # Walking under the branch cannot claim its reward.
	player.global_position = chest.global_position
	chest._unhandled_input(action)
	assert(chest.opened)
	assert(player_data.coin == initial_coins + 5)
	chest._unhandled_input(action)
	assert(player_data.coin == initial_coins + 5)
	player_data.coin = initial_coins
	room.queue_free()
	player.queue_free()
	await process_frame
	print("PASS: optional treasure requires proximity and pays exactly once.")
	quit()
