extends Node2D
## A continuous biome assembled from editable scenes. Used by graph_stage.gd.
const LAYOUT = preload("res://Script/Stage/Modular/level_layout.gd")
const NAVIGATION = preload("res://Script/Stage/Modular/room_navigation.gd")
const DEFAULT_SETTINGS = preload("res://Scenes/Rooms/Modular/default_level_settings.tres")
const SOLID_TILES = preload("res://Assets/Tileset/modular_solid.tres")
const BACKDROP_TILES = preload("res://Assets/Tileset/coastal_tileset.tres")
const MAP = preload("res://Script/UI/coastal_map.gd")
const REWARD = preload("res://Script/Interactables/modular_reward.gd")
@export var settings: Resource = DEFAULT_SETTINGS
var layout: Dictionary = {}
var exit_open := false

static func generate_layout(seed_value: int, config: Resource = DEFAULT_SETTINGS) -> Dictionary:
	return LAYOUT.new().generate(seed_value, config)

static func validate_layout(candidate: Dictionary) -> PackedStringArray:
	var errors := LAYOUT.validate(candidate)
	if not errors.is_empty():
		return errors
	var navigation := NAVIGATION.build(candidate)
	var start := NAVIGATION.surface_at(navigation, candidate.spawn)
	var destinations: Array = [candidate.exit, candidate.reward] + candidate.enemies
	for reward in candidate.rewards:
		destinations.append(reward.position)
	for point in destinations:
		var target := NAVIGATION.surface_at(navigation, point)
		if NAVIGATION.route(navigation, start, target).is_empty() or NAVIGATION.route(navigation, target, start).is_empty():
			errors.append("No baseline-jump round trip to marker at %s. Check painted landings." % point)
	return errors

func prepare(seed_value: int) -> bool:
	var candidate := generate_layout(seed_value, settings)
	var errors := validate_layout(candidate)
	if not errors.is_empty():
		push_error("Modular level rejected: " + "; ".join(errors))
		return false
	for child in get_children():
		remove_child(child)
		child.free()
	layout = candidate
	exit_open = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var exterior := CanvasLayer.new()
	exterior.name = "Exterior"
	exterior.layer = -100
	var shade := ColorRect.new()
	shade.color = Color("0a101b")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exterior.add_child(shade)
	add_child(exterior)
	var modules := Node2D.new()
	modules.name = "Rooms"
	add_child(modules)
	for data in layout.rooms:
		var instance: Node2D = data.definition.scene.instantiate()
		instance.name = "%02d_%s" % [data.id, data.definition.id]
		instance.position = data.position
		instance.open_sockets(data.used_sockets)
		modules.add_child(instance)
	var corridors := Node2D.new()
	corridors.name = "Corridors"
	add_child(corridors)
	var solid := TileMapLayer.new()
	solid.name = "Solid"
	solid.tile_set = SOLID_TILES
	corridors.add_child(solid)
	var background := TileMapLayer.new()
	background.name = "Backdrop"
	background.tile_set = BACKDROP_TILES
	background.z_index = -8
	background.modulate = Color(0.48, 0.57, 0.65)
	background.collision_enabled = false
	corridors.add_child(background)
	for connection in layout.connections:
		var rect: Rect2 = connection.region
		for x in range(roundi(rect.position.x / 16), roundi(rect.end.x / 16)):
			var ceiling_y := roundi(rect.position.y / 16) - 1
			var floor_y := roundi(rect.end.y / 16)
			solid.set_cell(Vector2i(x, ceiling_y), 0, Vector2i(posmod(x, 8), 1))
			solid.set_cell(Vector2i(x, floor_y), 0, Vector2i(posmod(x, 8), 0))
			for y in range(ceiling_y + 1, floor_y):
				background.set_cell(Vector2i(x, y), 0, Vector2i(posmod(x, 8), 2))
	var rewards := Node2D.new()
	rewards.name = "Rewards"
	add_child(rewards)
	var artifacts: Array = player_data.bestiary_master.get("artifacts", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5A17
	for i in range(layout.rewards.size()):
		var data: Dictionary = layout.rewards[i]
		var reward := REWARD.new()
		reward.name = "Reward%d" % i
		reward.position = data.position
		reward.reward_kind = data.kind
		if data.kind == "artifact" and not artifacts.is_empty():
			reward.artifact_name = artifacts[rng.randi_range(0, artifacts.size() - 1)].name
		rewards.add_child(reward)
	marker(self, "PlayerSpawn", layout.spawn)
	marker(self, "RewardSpawn", layout.reward)
	var doors := Node2D.new()
	doors.name = "DoorSpawns"
	add_child(doors)
	marker(doors, "Exit", layout.exit)
	var enemies := Node2D.new()
	enemies.name = "EnemySpawns"
	add_child(enemies)
	for i in range(layout.enemies.size()):
		marker(enemies, "Enemy%d" % i, layout.enemies[i])
	var hint := Label.new()
	hint.name = "ExitHint"
	hint.position = layout.exit + Vector2(-32, -48)
	hint.text = "EXIT\nKalahkan musuh"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.85, 0.75, 0.5)
	add_child(hint)
	set_meta("playable_bounds", layout.bounds)
	set_meta("map_regions", layout.regions)
	set_meta("modular_level", true)
	var map_overlay := MAP.new()
	map_overlay.name = "CoastalMap"
	map_overlay.room = self
	add_child(map_overlay)
	return true

func open_exit() -> void:
	exit_open = true
	$ExitHint.text = "EXIT TERBUKA"

func marker(parent: Node, marker_name: String, point: Vector2) -> void:
	var node := Marker2D.new()
	node.name = marker_name
	node.position = point
	parent.add_child(node)
