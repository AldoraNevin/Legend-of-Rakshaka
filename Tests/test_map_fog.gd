extends SceneTree
class MapRoom extends Node2D:
	var layout := {}
class Enemy extends Node2D:
	var health := 3
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var room := MapRoom.new()
	root.add_child(room)
	var player := Node2D.new()
	room.add_child(player)
	player.add_to_group("player")
	var enemy := Enemy.new()
	enemy.position = Vector2(199, 0)
	room.add_child(enemy)
	enemy.add_to_group("artifact_enemies")
	var view = load("res://Script/UI/coastal_map_view.gd").new()
	view.room = room
	view.hide()
	room.add_child(view)
	assert(not view.is_explored(Vector2.ZERO))
	view._physics_process(0.2)
	assert(view.is_explored(Vector2.ZERO))
	assert(not view.is_explored(Vector2(1000, 1000)))
	assert(view.spotted_enemies.has(enemy.get_instance_id()))
	assert(view.is_explored(enemy.position), "Detected enemies on the fog boundary must be visible")
	var body_shape := CollisionShape2D.new()
	body_shape.shape = RectangleShape2D.new()
	body_shape.position = Vector2(0, -30)
	enemy.add_child(body_shape)
	assert(view.sight_position(enemy) == enemy.global_position + Vector2(0, -30))
	enemy.position = Vector2(900, 0)
	view._physics_process(0.2)
	assert(view.spotted_enemies[enemy.get_instance_id()].position == Vector2(199, 0))
	enemy.health = 0
	view._physics_process(0.2)
	assert(view.spotted_enemies.is_empty())
	view.reveal_at(Vector2(1000, 1000))
	assert(view.is_explored(Vector2.ZERO))
	var doors := Node2D.new()
	doors.name = "DoorSpawns"
	room.add_child(doors)
	var exit_marker := Marker2D.new()
	exit_marker.name = "Exit"
	exit_marker.position = Vector2(2400, 0)
	doors.add_child(exit_marker)
	view.reveal_exit_area()
	assert(view.is_explored(exit_marker.position + Vector2(64, 0)))
	assert(not view.is_explored(Vector2(1600, 0)))
	room.queue_free()
	await process_frame
	print("MAP FOG TEST: passed")
	quit()
