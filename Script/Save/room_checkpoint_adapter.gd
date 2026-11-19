extends RefCounted
## Compatibility boundary: observes existing generator API without editing levels.
const GENERATOR := "res://Script/Stage/graph_stage.gd"
const GRAPH := preload("res://Script/Stage/stage_graph.gd")

static func supports(node: Node) -> bool:
	var script: Script = node.get_script()
	while script != null:
		if script.resource_path == GENERATOR:
			return true
		script = script.get_base_script()
	return false

static func signature(scene_path: String, room_path: String) -> String:
	var parts := ""
	for path in [GENERATOR, "res://Script/level_2_generator.gd", "res://Script/Stage/stage_graph.gd", scene_path, room_path]:
		parts += FileAccess.get_sha256(path)
	# Generated rooms also depend on stage helper scripts, not only their .tscn.
	var scripts := DirAccess.get_files_at("res://Script/Stage")
	scripts.sort()
	for name in scripts:
		if name.ends_with(".gd"):
			parts += FileAccess.get_sha256("res://Script/Stage/" + name)
	return parts.sha256_text()

static func capture(stage: Node) -> Dictionary:
	if not supports(stage) or not is_instance_valid(stage.current_room) or player_data.life <= 0:
		return {}
	var room: Dictionary = stage.stage_graph[stage.node_id]
	var path: String = stage.scene_file_path
	var room_path: String = stage.current_room.scene_file_path
	return {
		"version": 1, "scene": path, "room_scene": room_path,
		"signature": signature(path, room_path), "seed": stage.stage_seed,
		"room_id": stage.node_id, "room_label": room.label,
		"room_index": stage.current_room_index, "rng_state": str(stage.rng.state),
		"saved_at": Time.get_datetime_string_from_system(),
		"player": capture_player(), "exploration": capture_exploration(stage),
		"stats": {"speed": stage.player.speed, "jump_force": stage.player.jump_force,
			"sword_damage": stage.player.sword_damage, "max_jump": stage.player.max_jump}
	}

# JSON cannot preserve Vector2i dictionary keys; store cells as coordinate pairs.
static func capture_exploration(stage: Node) -> Dictionary:
	var cells: Array = []
	var portals: Array = []
	var map: Node = stage.current_room.get_node_or_null("CoastalMap")
	if map != null:
		for cell in map.view.explored:
			cells.append([cell.x, cell.y])
	var network: Node = stage.current_room.get_node_or_null("PortalNetwork")
	if network != null:
		for portal in network.portals:
			if portal.unlocked:
				portals.append(portal.portal_id)
	return {"cells": cells, "portals": portals}

static func restore_exploration(stage: Node, data: Dictionary) -> void:
	var exploration: Dictionary = data.get("exploration", {})
	var map: Node = stage.current_room.get_node_or_null("CoastalMap")
	if map != null:
		map.view.explored.clear()
		for cell in exploration.get("cells", []):
			map.view.explored[Vector2i(int(cell[0]), int(cell[1]))] = true
		map.view.queue_redraw()
	var network: Node = stage.current_room.get_node_or_null("PortalNetwork")
	if network != null:
		for portal in network.portals:
			portal.unlocked = portal.portal_id in exploration.get("portals", [])
			portal.queue_redraw()

static func exploration_error(data: Variant) -> String:
	if not data is Dictionary or not data.get("cells", []) is Array or not data.get("portals", []) is Array:
		return "Data eksplorasi tidak valid."
	for cell in data.get("cells", []):
		if not cell is Array or cell.size() != 2:
			return "Data area peta tidak valid."
		for coordinate in cell:
			if not (coordinate is int or coordinate is float):
				return "Koordinat peta tidak valid."
			if not is_finite(float(coordinate)) or absf(float(coordinate)) > 1000000 or float(coordinate) != floor(float(coordinate)):
				return "Koordinat peta di luar batas."
	for portal in data.get("portals", []):
		if not portal is String:
			return "Data portal tidak valid."
	return ""

static func capture_player() -> Dictionary:
	return {"fatal_shield_used": player_data.fatal_shield_used, "health_version": player_data.HEALTH_VERSION, "coin": player_data.coin, "life": maxi(1, player_data.life),
		"max_life": player_data.max_life, "upgrades": player_data.upgrade_levels.duplicate(true),
		"skills": player_data.unlocked_skill.duplicate(true),
		"enemies": player_data.discovered_enemies.duplicate(true),
		"artifacts": player_data.discovered_artifacts.duplicate(true)}

static func validation_error(data: Dictionary) -> String:
	if data.get("version") != 1:
		return "Versi checkpoint tidak didukung."
	for key in ["scene", "room_scene", "signature", "rng_state", "saved_at", "room_label"]:
		if not data.get(key) is String or str(data[key]).is_empty():
			return "Data checkpoint tidak lengkap."
	for key in ["seed", "room_id", "room_index"]:
		if not (data.get(key) is int or data.get(key) is float):
			return "Data ruangan tidak valid."
	if int(data.seed) <= 0 or int(data.room_id) < 0 or int(data.room_id) >= GRAPH.KINDS.size():
		return "Checkpoint ruangan tidak valid."
	if not data.rng_state.is_valid_int():
		return "Seed checkpoint tidak valid."
	if not str(data.scene).begins_with("res://") or not ResourceLoader.exists(data.scene) or not ResourceLoader.exists(data.room_scene):
		return "Scene level sudah dipindahkan atau tidak tersedia."
	if data.signature != signature(data.scene, data.room_scene):
		return "Level berubah sejak checkpoint dibuat. Mulai perjalanan baru."
	if not data.get("player") is Dictionary or not data.get("stats") is Dictionary:
		return "Data pemain tidak tersedia."
	var exploration_issue := exploration_error(data.get("exploration", {}))
	if not exploration_issue.is_empty():
		return exploration_issue
	var error := player_error(data.player)
	if not error.is_empty():
		return error
	for key in ["speed", "jump_force", "sword_damage", "max_jump"]:
		if not (data.stats.get(key) is int or data.stats.get(key) is float) or not is_finite(float(data.stats[key])) or data.stats[key] <= 0:
			return "Statistik karakter tidak valid."
	return ""

static func player_error(p: Dictionary) -> String:
	for key in ["coin", "life", "max_life"]:
		if not (p.get(key) is float or p.get(key) is int) or not is_finite(float(p[key])):
			return "Statistik pemain tidak valid."
	if p.life <= 0 or p.max_life < 1 or p.life > p.max_life or p.coin < 0:
		return "Statistik pemain di luar batas."
	if p.get("health_version", 1) == player_data.HEALTH_VERSION:
		var artifacts: Array = p.get("artifacts", []) if p.get("artifacts") is Array else []
		var has_health_artifact := "jimat_kalimasada" in artifacts or "Jimat Kalimasada" in artifacts
		var valid_max := int(p.max_life) == player_data.MAX_HEALTH
		valid_max = valid_max or (has_health_artifact and int(p.max_life) == player_data.MAX_HEALTH + 25)
		if not valid_max:
			return "Batas HP tidak sesuai dengan artefak pemain."
	if not p.get("upgrades") is Dictionary:
		return "Data upgrade tidak valid."
	for key in player_data.UPGRADE_DATA:
		if not (p.upgrades.get(key) is int or p.upgrades.get(key) is float):
			return "Data upgrade tidak lengkap."
		if p.upgrades[key] < 0 or p.upgrades[key] > player_data.UPGRADE_DATA[key].max_level:
			return "Level upgrade tidak valid."
	for key in ["skills", "enemies", "artifacts"]:
		if not p.get(key) is Array:
			return "Data koleksi tidak valid."
	return ""

static func restore_player(data: Dictionary) -> void:
	var p: Dictionary = data.player
	player_data.discovered_artifacts = p.artifacts.duplicate()
	player_data.fatal_shield_used = bool(p.get("fatal_shield_used", false))
	player_data.coin = int(p.coin)
	player_data.restore_health(int(p.life), int(p.max_life), int(p.get("health_version", 1)))
	for key in player_data.upgrade_levels:
		player_data.upgrade_levels[key] = int(p.upgrades[key])
	player_data.unlocked_skill = p.skills.duplicate()
	player_data.discovered_enemies = p.enemies.duplicate()
	player_data.discovered_artifacts = p.artifacts.duplicate()
	player_data.sync_bestiary_status()
