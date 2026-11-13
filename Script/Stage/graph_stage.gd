extends "res://Script/level_2_generator.gd"

signal stage_completed

const Graph = preload("res://Script/Stage/stage_graph.gd")
@export_range(0, 8) var preview_start_node := 0
@export var template_directory := "res://Scenes/Rooms/Stage/"
@export_file("*.tscn") var tutorial_room_scene := "res://Scenes/Rooms/Stage/tutorial_room.tscn"
var stage_graph: Array[Dictionary] = []
var node_id := 0
var templates: Dictionary = {}
var stage_finished := false
var stage_seed := 0

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
			path = template_directory + "coastal_room.tscn"
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
		return
	print("Graph stage seed: ", run_seed, " | nodes: ", stage_graph.size())
	node_id = preview_start_node
	stage_finished = false
	current_room_index = 0
	load_next_room()

func build_template_room(template: PackedScene) -> void:
	if stage_graph[node_id].kind == "combat":
		current_room = template.instantiate() as Node2D
		if not current_room.prepare(stage_graph[node_id].room_seed):
			current_room.free()
			current_room = null
			get_tree().paused = true
			return
		print(stage_graph[node_id].label, " seed: ", stage_graph[node_id].room_seed)
		room_root.add_child(current_room)
		spawn_from_markers("EnemySpawns", ENEMY_SCENE, enemies)
		spawn_from_markers("SpikeSpawns", SPIKE_SCENE, spikes)
	else:
		super.build_template_room(template)
	var title := current_room.get_node_or_null("Title") as Label
	if title != null and stage_graph[node_id].kind != "start":
		title.text = stage_graph[node_id].label

func complete_combat() -> void:
	if stage_graph[node_id].kind == "start":
		current_state = RoomState.DOOR_SELECT
		show_door_choices()
	else:
		super.complete_combat()
		if current_room.has_method("open_exit"):
			current_room.open_exit()

func pick_room_template() -> PackedScene:
	return templates[node_id]

func show_door_choices() -> void:
	hide_doors()
	var targets: Array = stage_graph[node_id].next
	if targets.is_empty():
		stage_finished = true
		stage_completed.emit()
		var message := Label.new()
		message.text = "STAGE SELESAI"
		message.position = Vector2(320, 260)
		room_root.add_child(message)
		return
	var positions := get_template_door_positions()
	for i in range(targets.size()):
		var target: int = targets[i]
		var door := create_door(i)
		door.body_entered.disconnect(_on_door_body_entered)
		door.body_entered.connect(_enter_graph_door.bind(target))
		for child in door.get_children():
			if child is Label:
				child.text = stage_graph[target].label
		door_root.add_child(door)
		door.global_position = positions[i]

func _enter_graph_door(body: Node2D, target: int) -> void:
	if current_state != RoomState.DOOR_SELECT or stage_finished or not body.is_in_group("player"):
		return
	if target not in stage_graph[node_id].next:
		return
	if current_room.has_method("can_exit") and not current_room.can_exit():
		current_room.show_gate_hint()
		return
	current_state = RoomState.COMBAT
	node_id = target
	# Leave the physics callback before adding/removing collision objects.
	call_deferred("load_next_room")
