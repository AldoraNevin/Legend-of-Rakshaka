@tool
extends Resource
## All randomness belongs here. Room geometry belongs to the .tscn templates.
@export_group("Layout")
@export_range(6, 24) var main_rooms_min := 10
@export_range(6, 24) var main_rooms_max := 13
@export_range(1, 4) var treasure_rooms := 2
@export_range(1, 3) var artifact_rooms := 1
@export_range(0, 3) var branch_combat_min := 0
@export_range(0, 3) var branch_combat_max := 1
@export_range(3, 12) var corridor_min_tiles := 4
@export_range(3, 12) var corridor_max_tiles := 8
@export_range(0.0, 1.0) var rightward_bias := 0.65
## Higher values fold the main path back across previous rooms on another floor.
@export_range(0.0, 1.0) var foldback_chance := 0.85
@export_range(0.0, 1.0) var upward_bias := 0.95
## Soft target: retry overly stretched layouts, retaining the best valid result.
@export_range(2.0, 8.0) var target_aspect_ratio := 3.5
@export_range(100, 50000) var search_budget := 18000
@export_group("Content")
## Advanced hand-painted rooms need playtesting: cell navigation cannot prove slopes/wall jumps.
@export var strict_traversal_validation := false
@export_range(0.0, 1.0) var enemy_spawn_chance := 0.75
@export var room_templates: Array[PackedScene] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if main_rooms_min < 6 or main_rooms_max < main_rooms_min or main_rooms_max > 24:
		errors.append("Main room range must be 6..24, min <= max.")
	if treasure_rooms < 1 or artifact_rooms < 1:
		errors.append("At least one treasure and one artifact room are required.")
	if branch_combat_min < 0 or branch_combat_max < branch_combat_min or branch_combat_max > 3:
		errors.append("Branch combat range must be 0..3, min <= max.")
	if corridor_min_tiles < 3 or corridor_max_tiles < corridor_min_tiles:
		errors.append("Corridor range must be >= 3 tiles, min <= max.")
	if room_templates.is_empty():
		errors.append("Room catalog is empty.")
	if room_templates.has(null):
		errors.append("Room catalog contains an empty scene slot.")
	if search_budget < 100 or target_aspect_ratio <= 0:
		errors.append("Search budget/aspect ratio must be positive.")
	return errors
