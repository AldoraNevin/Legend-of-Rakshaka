extends Node2D
const PORTAL := preload("res://Script/Interactables/level_portal.gd")
const RANGE := 60.0
var room: Node2D
var portals: Array[Node2D] = []
var nearby := -1
var source := -1
var owns_pause := false
var overlay: CanvasLayer
var menu: Control
var close_button: Button
var open_button: Button

func configure(level: Node2D) -> void:
	room = level
	for data in room.layout.rooms:
		if data.kind in ["treasure", "artifact"]:
			add_portal("Portal", data.position + data.definition.markers.PlayerSpawn, "%s_%d" % [data.kind, data.id])
		elif data.kind == "exit":
			# The exit door occupies PlayerSpawn. RewardSpawn is a separate safe landing.
			add_portal("Portal", data.position + data.definition.markers.RewardSpawn, "exit_%d" % data.id)

func add_portal(title: String, point: Vector2, portal_id: String) -> void:
	var portal := PORTAL.new()
	portal.title = title
	portal.position = point
	portal.portal_id = portal_id
	add_child(portal)
	portals.append(portal)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = CanvasLayer.new()
	overlay.layer = 110
	add_child(overlay)
	open_button = Button.new()
	open_button.text = "Portal [F]"
	open_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	open_button.position = Vector2(-85, -75)
	open_button.size = Vector2(170, 50)
	open_button.pressed.connect(open_menu)
	overlay.add_child(open_button)
	close_button = Button.new()
	close_button.text = "Kembali"
	close_button.size = Vector2(130, 44)
	close_button.pressed.connect(close_menu)
	overlay.add_child(close_button)
	close_button.hide()
	open_button.hide()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _process(_delta: float) -> void:
	if get_tree().paused:
		open_button.hide()
		return
	nearby = -1
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.get("is_dead") == true:
		open_button.hide()
		return
	var distance := RANGE
	for i in range(portals.size()):
		var portal := portals[i]
		var delta := player.global_position - portal.global_position
		if absf(delta.y) <= 35 and delta.length() < distance:
			distance = delta.length()
			nearby = i
	if nearby >= 0:
		portals[nearby].unlocked = true
		portals[nearby].queue_redraw()
	open_button.visible = nearby >= 0

func _input(event: InputEvent) -> void:
	if owns_pause and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		if nearby >= 0 and not get_tree().paused:
			open_menu()
			get_viewport().set_input_as_handled()

func open_menu() -> void:
	if nearby < 0 or get_tree().paused:
		return
	source = nearby
	menu = room.get_node("CoastalMap").view
	menu.portal_network = self
	room.get_node("CoastalMap").hint.hide()
	owns_pause = true
	get_tree().paused = true
	open_button.hide()
	menu.show()
	menu.queue_redraw()
	close_button.show()
	_layout_ui.call_deferred()

func teleport(index: int) -> void:
	if not owns_pause or index < 0 or index >= portals.size() or not portals[index].unlocked or index == source:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or player.get("is_dead") == true:
		close_menu()
		return
	player.global_position = portals[index].global_position
	player.velocity = Vector2.ZERO
	if player.has_method("reset_states"):
		player.reset_states()
	var stage := get_tree().current_scene
	if stage != null and stage.has_method("snap_camera_to_player"):
		stage.snap_camera_to_player()
	close_menu()

func close_menu() -> void:
	if is_instance_valid(menu):
		menu.portal_network = null
		menu.hide()
	close_button.hide()
	room.get_node("CoastalMap").hint.show()
	if owns_pause:
		owns_pause = false
		get_tree().paused = false
	source = -1

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false

func _layout_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	close_button.position = Vector2(viewport_size.x - 155, 75)
	open_button.position = Vector2((viewport_size.x - open_button.size.x) * 0.5, viewport_size.y - 75)
