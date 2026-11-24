extends "res://Script/level_2_generator.gd"

signal stage_completed

const Graph = preload("res://Script/Stage/stage_graph.gd")
const END_CREDITS := preload("res://addons/maaacks_menus_template/examples/scenes/end_credits/end_credits.tscn")
@export_range(0, 8) var preview_start_node := 0
@export var template_directory := "res://Scenes/Rooms/Stage/"
@export var procedural_level: PackedScene = preload("res://Scenes/Rooms/Modular/modular_level.tscn")
@export_file("*.tscn") var tutorial_room_scene := "res://Scenes/Rooms/Stage/tutorial_room.tscn"
var stage_graph: Array[Dictionary] = []
var node_id := 0
var templates: Dictionary = {}
var stage_finished := false
var stage_seed := 0
@export_range(1.0, 4.0, 0.1) var boss_camera_zoom := 1.9
@export_range(1.0, 4.0, 0.1) var tutorial_camera_zoom := 3.0
@onready var normal_camera_zoom: Vector2 = camera.zoom

func apply_camera_limits() -> void:
	super.apply_camera_limits()
	if not stage_graph.is_empty() and stage_graph[node_id].kind == "boss":
		camera.zoom = Vector2.ONE * boss_camera_zoom
		# Boss collision is painted in TileMapLayers, not StaticBody2D shapes.
		var origin := current_room.global_position
		camera.limit_left = int(origin.x) - 16
		camera.limit_top = int(origin.y) - 16
		camera.limit_right = int(origin.x) + int(current_room.get_meta("arena_width")) + 16
		camera.limit_bottom = int(origin.y) + 416
	elif not stage_graph.is_empty() and stage_graph[node_id].kind == "start":
		camera.zoom = Vector2.ONE * tutorial_camera_zoom
		# Frame the courtyard artwork, including the sky and paving below the floor.
		var origin := current_room.global_position
		camera.limit_left = int(origin.x)
		camera.limit_top = int(origin.y) + 14
		camera.limit_right = int(origin.x) + int(current_room.get_meta("arena_width", 832))
		camera.limit_bottom = int(origin.y) + 482
	else:
		camera.zoom = normal_camera_zoom

func start_run() -> void:
	var run_seed := random_seed if random_seed != 0 else int(rng.randi())
	stage_seed = run_seed
	stage_graph = Graph.generate(run_seed)
	var errors := Graph.validate(stage_graph)
	templates.clear()
	for room in stage_graph:
		var path := template_directory + "%s_%d.tscn" % [room.kind, room.variant]
		if room.kind == "start":
			path = tutorial_room_scene
		if room.kind == "combat":
			path = procedural_level.resource_path
		if not ResourceLoader.exists(path):
			errors.append("Template tidak ditemukan: " + path)
			continue
		var scene := load(path) as PackedScene
		if scene == null:
			errors.append("Resource bukan PackedScene: " + path)
			continue
		errors.append_array(Graph.validate_template(scene, room.next.size()))
		templates[room.id] = scene
	if not errors.is_empty():
		push_error("Stage dibatalkan: " + "; ".join(errors))
		show_generation_error(run_seed)
		return
	player.set_physics_process(true)
	print("Graph stage seed: ", run_seed, " | nodes: ", stage_graph.size())
	node_id = 1 if preview_start_node == 0 and player_data.tutorial_completed else preview_start_node
	stage_finished = false
	current_room_index = 0
	load_next_room()

func build_template_room(template: PackedScene) -> void:
	if stage_graph[node_id].kind == "combat":
		current_room = template.instantiate() as Node2D
		if not current_room.prepare(stage_graph[node_id].room_seed):
			current_room.free()
			current_room = null
			show_generation_error(stage_graph[node_id].room_seed)
			return
		print(stage_graph[node_id].label, " seed: ", stage_graph[node_id].room_seed)
		room_root.add_child(current_room)
		if current_room.get_meta("modular_level", false):
			for encounter in current_room.layout.encounters:
				var enemy := preload("res://Script/Stage/Modular/enemy_catalog.gd").create(encounter.species)
				enemy.set_meta("modular_room_id", encounter.room_id)
				enemies.add_child(enemy)
				enemy.global_position = current_room.to_global(encounter.position)
				# Enemies is a plain Node; reset the patrol origin after placement.
				enemy.home_x = enemy.global_position.x
		else:
			spawn_from_markers("EnemySpawns", ENEMY_SCENE, enemies)
		spawn_from_markers("SpikeSpawns", SPIKE_SCENE, spikes)
	else:
		super.build_template_room(template)
	if stage_graph[node_id].kind != "start":
		var music := AudioStreamPlayer.new()
		music.name = "RoomMusic"
		current_room.add_child(music)
		if stage_graph[node_id].kind == "boss":
			var battle := preload("res://Assets/Legend of Rakshaka/BGM/Boss Battle Extended Better.ogg").duplicate() as AudioStreamOggVorbis
			battle.loop = true
			music.bus = "Music"
			music.volume_db = -12
			music.stream = battle
			music.play()
		else:
			preload("res://Script/Audio/game_audio.gd").configure_music(music, false)
	var title := current_room.get_node_or_null("Title") as Label
	if title != null and stage_graph[node_id].kind != "start":
		title.text = stage_graph[node_id].label

func show_generation_error(seed_value: int) -> void:
	player.set_physics_process(false)
	var error_label := Label.new()
	error_label.text = "Level gagal dibuat (seed %d).\nPeriksa template/settings di Output Godot.\nEsc: menu jeda" % seed_value
	error_label.position = Vector2(32, 100)
	$GUI.add_child(error_label)

func complete_combat() -> void:
	if node_id == 1: # Room 1 is the first combat node after the tutorial.
		if stage_finished:
			return
		stage_finished = true
		_show_room_one_credits.call_deferred()
		return
	if stage_graph[node_id].kind == "start":
		current_state = RoomState.DOOR_SELECT
		show_door_choices()
	else:
		super.complete_combat()
		if current_room.has_method("open_exit"):
			current_room.open_exit()

func _show_room_one_credits() -> void:
	if is_inside_tree() and not is_queued_for_deletion() and get_tree().current_scene == self:
		get_tree().change_scene_to_packed(END_CREDITS)

func pick_room_template() -> PackedScene:
	return templates[node_id]

func show_door_choices() -> void:
	hide_doors()
	var targets: Array = stage_graph[node_id].next
	if targets.is_empty():
		if stage_finished:
			return
		stage_finished = true
		stage_completed.emit()
		var portal := LobbyPortal.new()
		portal.title = "Kembali ke lobi [F]"
		portal.unlocked = true
		door_root.add_child(portal)
		var marker = current_room.get_node("DoorSpawns/Marker0")
		portal.global_position = marker.to_global(marker.floor_offset)
		return
	var positions := get_template_door_positions()
	for i in range(targets.size()):
		var target: int = targets[i]
		var door := create_door(i)
		if current_room.has_method("configure_exit_visual"):
			current_room.configure_exit_visual(door, i)
		door.body_entered.disconnect(_on_door_body_entered)
		door.body_entered.connect(_enter_graph_door.bind(target))
		for child in door.get_children():
			if child is Label:
				child.text = stage_graph[target].label
		door_root.add_child(door)
		door.global_position = positions[i]

func _enter_graph_door(body: Node2D, target: int) -> void:
	if RoomLoading.busy or current_state != RoomState.DOOR_SELECT or stage_finished or not body.is_in_group("player"):
		return
	if target not in stage_graph[node_id].next:
		return
	if current_room.has_method("can_exit") and not current_room.can_exit():
		current_room.show_gate_hint()
		return
	current_state = RoomState.COMBAT
	# Leave the physics callback before rendering/loading the next room.
	travel_to_room.call_deferred(target)


func travel_to_room(target: int) -> void:
	if RoomLoading.busy:
		return
	await RoomLoading.change_room(func():
		stage_finished = false
		node_id = target
		load_next_room()
		player.velocity = Vector2.ZERO
	, "Memuat %s..." % stage_graph[target].label)


class LobbyPortal extends "res://Script/Interactables/level_portal.gd":
	var leaving := false

	func _unhandled_key_input(event: InputEvent) -> void:
		if leaving or not event is InputEventKey or not event.pressed or event.echo or event.physical_keycode != KEY_F:
			return
		var hero := get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(hero) or hero.get("is_dead") or hero.global_position.distance_to(global_position) > 65:
			return
		if CheckpointManager.active_slot >= 0 and CheckpointManager.enabled:
			var checkpoint := {"version": 1, "scene": CheckpointManager.LOBBY, "room_label": "Lobby",
				"saved_at": Time.get_datetime_string_from_system(), "player": CheckpointManager.ADAPTER.capture_player()}
			if not CheckpointManager.save_checkpoint(checkpoint):
				return
		leaving = true
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file.call_deferred(CheckpointManager.LOBBY)
