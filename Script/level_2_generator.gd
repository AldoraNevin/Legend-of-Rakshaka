extends Node2D

const TILE_SOURCE := 0
const TILE_SIZE := 16
const SOLID_TILE := Vector2i(1, 1)
const SURFACE_TILE := Vector2i(1, 0)
const LEFT_EDGE_TILE := Vector2i(0, 1)
const RIGHT_EDGE_TILE := Vector2i(2, 1)

const COIN_SCENE := preload("res://Scenes/Interactables/coin.tscn")
const ENEMY_SCENE := preload("res://Scenes/Enemies/Aul.tscn")
const SPIKE_SCENE := preload("res://Scenes/Interactables/spike.tscn")
const ENEMY_SCALE := Vector2(0.5, 0.5)

enum RoomState { COMBAT, REWARD, DOOR_SELECT }

@export_group("Run Flow")
@export var rooms_per_run := 6
@export var random_seed := 0
@export_range(1, 3, 1) var min_door_choices := 2
@export_range(1, 3, 1) var max_door_choices := 3

@export_group("Handmade Room Templates")
@export var room_templates: Array[PackedScene] = []
@export var boss_room_templates: Array[PackedScene] = []

@export_group("Fallback Room")
@export var room_size := Vector2i(34, 18)
@export_range(1, 6, 1) var fallback_enemy_min := 2
@export_range(1, 6, 1) var fallback_enemy_max := 4

@onready var tile_map: TileMap = $TileMap
@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var enemies: Node = $Enemies
@onready var coins: Node = $Coin
@onready var spikes: Node = $Spike
@onready var room_root: Node2D = $RoomRoot
@onready var door_root: Node2D = $Doors

var rng := RandomNumberGenerator.new()
var current_room_index := 0
var current_state := RoomState.COMBAT
var current_room: Node2D = null
var active_reward: Node2D = null
var active_enemies: Array[Node] = []


func _ready() -> void:
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed

	start_run()


func start_run() -> void:
	current_room_index = 0
	load_next_room()


func load_next_room() -> void:
	current_room_index += 1
	current_state = RoomState.COMBAT
	active_reward = null
	active_enemies.clear()
	clear_room()

	var template: PackedScene = pick_room_template()
	if template != null:
		build_template_room(template)
		if current_room == null:
			return
	else:
		build_fallback_room()

	position_player()
	register_room_enemies()
	hide_doors()
	apply_camera_limits()
	snap_camera_to_player()

	if active_enemies.is_empty():
		complete_combat()


func pick_room_template() -> PackedScene:
	var is_boss_room: bool = current_room_index >= rooms_per_run

	if is_boss_room and not boss_room_templates.is_empty():
		return boss_room_templates[rng.randi_range(0, boss_room_templates.size() - 1)]

	if not room_templates.is_empty():
		return room_templates[rng.randi_range(0, room_templates.size() - 1)]

	return null


func clear_room() -> void:
	tile_map.clear_layer(0)

	for node in enemies.get_children():
		node.queue_free()

	for node in coins.get_children():
		node.queue_free()

	for node in spikes.get_children():
		node.queue_free()

	for node in door_root.get_children():
		node.queue_free()

	for node in room_root.get_children():
		node.queue_free()


func build_template_room(template: PackedScene) -> void:
	current_room = template.instantiate() as Node2D
	room_root.add_child(current_room)

	spawn_from_markers("EnemySpawns", ENEMY_SCENE, enemies)
	spawn_from_markers("SpikeSpawns", SPIKE_SCENE, spikes)


func update_camera_limits_for_template() -> void:
	if current_room == null:
		return
	if current_room.has_meta("playable_bounds"):
		var bounds: Rect2 = current_room.get_meta("playable_bounds")
		bounds.position += current_room.global_position
		camera.limit_left = floori(bounds.position.x)
		camera.limit_top = floori(bounds.position.y)
		camera.limit_right = ceili(bounds.end.x)
		camera.limit_bottom = ceili(bounds.end.y)
		return

	# Cari batas room dari semua StaticBody2D (lantai, dinding, langit-langit)
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for body in current_room.find_children("*", "CollisionShape2D", true, false):
		var shape_owner := body as CollisionShape2D
		if shape_owner == null:
			continue
		var gpos: Vector2 = shape_owner.global_position
		if body.shape is RectangleShape2D:
			var half: Vector2 = (body.shape as RectangleShape2D).size * 0.5
			min_x = minf(min_x, gpos.x - half.x)
			min_y = minf(min_y, gpos.y - half.y)
			max_x = maxf(max_x, gpos.x + half.x)
			max_y = maxf(max_y, gpos.y + half.y)

	if is_inf(min_x) or is_inf(max_x):
		# Fallback jika tidak ditemukan shape
		update_camera_limits()
		return

	camera.limit_left   = int(min_x)
	camera.limit_top    = int(min_y)
	camera.limit_right  = int(max_x)
	camera.limit_bottom = int(max_y)


func spawn_from_markers(marker_group_name: String, scene: PackedScene, parent: Node) -> void:
	var marker_group: Node = current_room.get_node_or_null(marker_group_name)
	if marker_group == null:
		return

	for marker in marker_group.get_children():
		if marker is Node2D:
			var instance: Node2D = scene.instantiate() as Node2D
			parent.add_child(instance)
			instance.global_position = marker.global_position
			if scene == ENEMY_SCENE:
				instance.scale = ENEMY_SCALE


func build_fallback_room() -> void:
	current_room = null
	var floor_tile_y: int = room_size.y - 2

	for local_x in range(room_size.x):
		set_tile(Vector2i(local_x, 0), SURFACE_TILE)
		set_tile(Vector2i(local_x, floor_tile_y), SURFACE_TILE)
		set_tile(Vector2i(local_x, floor_tile_y + 1), SOLID_TILE)

	for local_y in range(1, floor_tile_y):
		set_tile(Vector2i(0, local_y), LEFT_EDGE_TILE)
		set_tile(Vector2i(room_size.x - 1, local_y), RIGHT_EDGE_TILE)

	build_fallback_platforms()
	build_fallback_spikes()
	build_fallback_enemies()


func build_fallback_platforms() -> void:
	var layouts: Array = [
		[Vector3i(5, 11, 7), Vector3i(18, 8, 8), Vector3i(9, 5, 5)],
		[Vector3i(6, 10, 5), Vector3i(14, 7, 7), Vector3i(24, 10, 4)],
		[Vector3i(4, 8, 6), Vector3i(15, 5, 5), Vector3i(23, 8, 6)],
	]
	var layout: Array = layouts[rng.randi_range(0, layouts.size() - 1)]

	for platform_data in layout:
		var platform: Vector3i = platform_data
		for offset in range(platform.z):
			set_tile(Vector2i(platform.x + offset, platform.y), SURFACE_TILE)


func build_fallback_spikes() -> void:
	if rng.randf() > 0.65:
		return

	var floor_tile_y: int = room_size.y - 2
	var spike_count: int = rng.randi_range(3, 7)
	var start_x: int = rng.randi_range(11, 20)

	for i in range(spike_count):
		var spike: Node2D = SPIKE_SCENE.instantiate() as Node2D
		spikes.add_child(spike)
		spike.global_position = tile_to_world(Vector2i(start_x + i, floor_tile_y - 1))


func build_fallback_enemies() -> void:
	var floor_tile_y: int = room_size.y - 2
	var enemy_count: int = rng.randi_range(fallback_enemy_min, fallback_enemy_max)

	if current_room_index >= rooms_per_run:
		enemy_count += 1

	for i in range(enemy_count):
		var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
		enemies.add_child(enemy)
		enemy.scale = ENEMY_SCALE
		enemy.global_position = tile_to_world(Vector2i(rng.randi_range(8, room_size.x - 8), floor_tile_y - 1))


func position_player() -> void:
	var spawn: Node2D = get_template_marker("PlayerSpawn")
	if spawn != null:
		player.global_position = spawn.global_position
		return

	player.global_position = tile_to_world(Vector2i(3, room_size.y - 3))


func register_room_enemies() -> void:
	active_enemies.clear()

	for enemy in enemies.get_children():
		register_enemy(enemy)

	if current_room != null:
		for node in current_room.find_children("*", "CharacterBody2D", true, false):
			if node.has_method("take_damage"):
				register_enemy(node)


func register_enemy(enemy: Node) -> void:
	if enemy.is_queued_for_deletion() or enemy in active_enemies:
		return

	active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_removed(enemy: Node) -> void:
	active_enemies.erase(enemy)

	if current_state == RoomState.COMBAT and active_enemies.is_empty():
		complete_combat()


func complete_combat() -> void:
	current_state = RoomState.DOOR_SELECT
	spawn_reward()
	show_door_choices()


func spawn_reward() -> void:
	var reward_spawn: Node2D = get_template_marker("RewardSpawn")
	var reward_position: Vector2 = tile_to_world(Vector2i(floori(room_size.x / 2.0), room_size.y - 5))

	if reward_spawn != null:
		reward_position = reward_spawn.global_position

	active_reward = COIN_SCENE.instantiate() as Node2D
	coins.add_child(active_reward)
	active_reward.global_position = reward_position
	active_reward.tree_exited.connect(_on_reward_taken, CONNECT_ONE_SHOT)


func _on_reward_taken() -> void:
	if current_state != RoomState.REWARD:
		return

	current_state = RoomState.DOOR_SELECT
	show_door_choices()


func show_door_choices() -> void:
	hide_doors()

	var door_positions: Array[Vector2] = get_template_door_positions()
	if door_positions.is_empty():
		door_positions = get_fallback_door_positions()

	var door_count: int = mini(rng.randi_range(min_door_choices, max_door_choices), door_positions.size())
	for i in range(door_count):
		var door: Area2D = create_door(i)
		door_root.add_child(door)
		door.global_position = door_positions[i]


func create_door(index: int) -> Area2D:
	var door: Area2D = Area2D.new()
	door.name = "NextRoomDoor%d" % (index + 1)
	door.collision_layer = 0
	door.collision_mask = 1
	door.body_entered.connect(_on_door_body_entered)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(36, 64)
	shape.shape = rectangle
	door.add_child(shape)

	var marker: Polygon2D = Polygon2D.new()
	marker.color = Color(0.72, 0.24, 0.2, 0.9)
	marker.polygon = PackedVector2Array([
		Vector2(-18, 32),
		Vector2(-18, -20),
		Vector2(0, -34),
		Vector2(18, -20),
		Vector2(18, 32),
	])
	door.add_child(marker)

	var label: Label = Label.new()
	label.text = pick_door_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_left = -56
	label.offset_top = 34
	label.offset_right = 56
	label.offset_bottom = 58
	door.add_child(label)

	return door


func pick_door_label() -> String:
	var labels: Array[String] = ["Hutan", "Ritual", "Trap", "Relik", "Elite"]
	return labels[rng.randi_range(0, labels.size() - 1)]


func _on_door_body_entered(body: Node2D) -> void:
	if current_state != RoomState.DOOR_SELECT:
		return

	if body.is_in_group("player"):
		current_state = RoomState.COMBAT
		call_deferred("load_next_room")


func hide_doors() -> void:
	for node in door_root.get_children():
		node.queue_free()


func get_template_marker(marker_name: String) -> Node2D:
	if current_room == null:
		return null

	var marker: Node = current_room.get_node_or_null(marker_name)
	if marker is Node2D:
		return marker

	return null


func get_template_door_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if current_room == null:
		return positions

	var marker_group: Node = current_room.get_node_or_null("DoorSpawns")
	if marker_group == null:
		return positions

	for marker in marker_group.get_children():
		if marker is Node2D:
			positions.append(marker.global_position)

	return positions


func get_fallback_door_positions() -> Array[Vector2]:
	var floor_y: int = (room_size.y - 2) * TILE_SIZE
	return [
		Vector2((room_size.x - 7) * TILE_SIZE, floor_y - 96),
		Vector2((room_size.x - 4) * TILE_SIZE, floor_y - 32),
		Vector2((room_size.x - 10) * TILE_SIZE, floor_y - 32),
	]


func set_tile(tile_pos: Vector2i, atlas_pos: Vector2i) -> void:
	tile_map.set_cell(0, tile_pos, TILE_SOURCE, atlas_pos)


func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return tile_map.to_global(tile_map.map_to_local(tile_pos))


func apply_camera_limits() -> void:
	if current_room != null:
		update_camera_limits_for_template()
	else:
		update_camera_limits()


func snap_camera_to_player() -> void:
	if camera.has_method("snap_to_target"):
		camera.snap_to_target()
	else:
		camera.global_position = player.global_position
		camera.reset_smoothing()


func update_camera_limits() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = room_size.x * TILE_SIZE
	camera.limit_bottom = room_size.y * TILE_SIZE
