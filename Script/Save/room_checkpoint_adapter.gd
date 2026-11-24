extends RefCounted
## Compatibility boundary: observes existing generator API without editing levels.
# These gameplay-only changes preserve the generated layout of existing saves.
const PRE_TUTORIAL_UPDATE_HASHES := {
	"res://Script/Stage/graph_stage.gd": "39e771d07683b290b9bac989a1e86672baf79954113af182ee174a3a852db455",
	"res://Script/Stage/tutorial_room.gd": "76d07a6c7810753766b02f19794186c2ea7b68f0c6c167ea8e1c89885186402f"
}
const PRE_BOSS_MUSIC_HASHES := {
	"res://Script/Stage/graph_stage.gd": "8db2ef44ec8df4681d0e0f95696c993e70dfc4ba8dbf0c5fc9ed8ff3f90b473f",
	"res://Scenes/Rooms/Stage/tutorial_room.tscn": "8978115e582f55ac6092fe5ba341230567afeff22eb0c21ee0e85ea32ffe1fb0",
}
const PRE_FIVE_STAGE_HASHES := {
	"res://Script/Stage/graph_stage.gd": "5f3fe9cfbf9ba3546915cc413536c5e37b4446912be1903a9ea88619dff68d15",
	"res://Script/Stage/stage_graph.gd": "3273589a54eeafdd8dfe311683f71062a6d3ca559f23d9ed1f7fac90ac189872",
	"res://Script/Stage/tutorial_room.gd": "99ca85bd68707f933808ef5cf8530577b46f6267ce983d29aeb61a859f4b6807",
}
const GENERATOR := "res://Script/Stage/graph_stage.gd"
const GRAPH := preload("res://Script/Stage/stage_graph.gd")

static func supports(node: Node) -> bool:
	var script: Script = node.get_script()
	while script != null:
		if script.resource_path == GENERATOR:
			return true
		script = script.get_base_script()
	return false

static func layout_hash(path: String, lf_source: bool) -> String:
	var digest := FileAccess.get_sha256(path)
	match digest:
		"0c27550dd9bc708bfe6b529660a2064c7f90ed4b6a9e9a36d712a09c07ae91da": return "0831f981116bb42ad14e2bbba13361401ba40deec9f59ed45e02c956e10bfc39" if lf_source else "980f1bb15bf34fdb0ab8f89b0fd4e2b7f5290dd6e26571da826bcee88ff189e4"
		"19b044280f61d86808ee097ae2ff619895f9d04877355bc7798060d066141c08": return "ac28eed61f085954bca7572dcce555a702e80630243417af3b718d70a2855678" if lf_source else "728a879398158742b1bb8dc1e2f34a8c6c67bb387bae5e6de543d07b4f806f79"
	return digest

static func signature(scene_path: String, room_path: String, previous_tutorial := false, previous_boss_music := false, lf_source := false, previous_route := false) -> String:
	var previous: Dictionary = PRE_TUTORIAL_UPDATE_HASHES if previous_tutorial else {}
	if previous_boss_music:
		previous = PRE_BOSS_MUSIC_HASHES
	if previous_route:
		previous = PRE_FIVE_STAGE_HASHES
	var parts := ""
	for path in [GENERATOR, "res://Script/level_2_generator.gd", "res://Script/Stage/stage_graph.gd", scene_path, room_path]:
		parts += previous.get(path, layout_hash(path, lf_source))
	# Generated rooms also depend on stage helper scripts, not only their .tscn.
	var scripts := DirAccess.get_files_at("res://Script/Stage")
	scripts.sort()
	for name in scripts:
		if name.ends_with(".gd"):
			parts += previous.get("res://Script/Stage/" + name, layout_hash("res://Script/Stage/" + name, lf_source))
	return parts.sha256_text()

static func migrate_route(data: Dictionary) -> void:
	if not data.has("room_id") or not data.get("room_scene") is String or not data.get("scene") is String:
		return
	var old_id := int(data.room_id)
	if old_id < 0 or old_id > 8:
		return
	if data.get("signature") != signature(data.scene, data.room_scene, false, false, false, true):
		return
	var new_id: int = [0, 1, 2, 3, 4, 4, 5, 6, 6][old_id]
	var route := GRAPH.generate(int(data.seed))
	if old_id in [4, 7, 8]:
		data.exploration = {}
		data.room_scene = "res://Scenes/Rooms/Modular/modular_level.tscn" if new_id == 4 else "res://Scenes/Rooms/Stage/boss_%d.tscn" % route[new_id].variant
	data.room_id = new_id
	data.room_label = route[new_id].label
	data.room_index = new_id + 1
	data.signature = signature(data.scene, data.room_scene)

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
	return {"tutorial_completed": player_data.tutorial_completed, "attack_learned": player_data.attack_learned, "dash_learned": player_data.dash_learned, "fatal_shield_used": player_data.fatal_shield_used, "health_version": player_data.HEALTH_VERSION, "coin": player_data.coin, "life": maxi(1, player_data.life),
		"max_life": player_data.max_life, "upgrades": player_data.upgrade_levels.duplicate(true), "upgrade_version": player_data.UPGRADE_VERSION, "healing_skill": player_data.capture_healing_skill(),
		"skills": player_data.unlocked_skill.duplicate(true),
		"enemies": player_data.discovered_enemies.duplicate(true),
		"active_artifacts": player_data.active_artifacts.duplicate(),
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
	if data.signature != signature(data.scene, data.room_scene) and data.signature != signature(data.scene, data.room_scene, false, false, true) and data.signature != signature(data.scene, data.room_scene, true) and data.signature != signature(data.scene, data.room_scene, false, true):
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
	for key in ["tutorial_completed", "attack_learned", "dash_learned"]:
		if p.has(key) and not p[key] is bool:
			return "Data tutorial tidak valid."
	for key in ["coin", "life", "max_life"]:
		if not (p.get(key) is float or p.get(key) is int) or not is_finite(float(p[key])):
			return "Statistik pemain tidak valid."
	if p.life <= 0 or p.max_life < 1 or p.life > p.max_life or p.coin < 0:
		return "Statistik pemain di luar batas."
	if not p.get("upgrades") is Dictionary:
		return "Data upgrade tidak valid."
	for key in player_data.UPGRADE_DATA:
		var fallback = p.upgrades.get("speed", 0) if key == "skill_charge" else (p.upgrades.get("jump", 0) if key == "skill_cooldown" else null)
		var level = p.upgrades.get(key, fallback)
		if not (level is int or level is float) or not is_finite(float(level)):
			return "Data upgrade tidak lengkap."
		if level < 0 or level > player_data.UPGRADE_DATA[key].max_level or level != floor(level):
			return "Level upgrade tidak valid."
	if p.get("health_version", 1) == player_data.HEALTH_VERSION:
		var owned = p.get("active_artifacts", p.get("artifacts", []))
		if not owned is Array:
			return "Data artefak aktif tidak valid."
		var artifacts: Array = owned
		var bonus := 25 if "jimat_kalimasada" in artifacts or "Jimat Kalimasada" in artifacts else 0
		var expected := player_data.MAX_HEALTH + bonus
		if int(p.get("upgrade_version", 1)) >= 2:
			expected += int(p.upgrades.max_life) * 5
		if int(p.max_life) != expected:
			return "Batas HP tidak sesuai dengan upgrade dan artefak."
	if p.has("healing_skill"):
		if not p.healing_skill is Dictionary:
			return "Data skill tidak valid."
		for key in ["charges", "recharge_left", "interval_left"]:
			var value = p.healing_skill.get(key)
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0:
				return "Data cooldown skill tidak valid."
		if p.healing_skill.charges > 1 + int(p.upgrades.get("skill_charge", 0)) or p.healing_skill.charges != floor(p.healing_skill.charges) or p.healing_skill.recharge_left > 30 or p.healing_skill.interval_left > 3:
			return "Data charge skill di luar batas."
	for key in ["skills", "enemies", "artifacts"]:
		if not p.get(key) is Array:
			return "Data koleksi tidak valid."
	return ""

static func restore_player(data: Dictionary) -> void:
	var p: Dictionary = data.player
	player_data.restore_tutorial(p, int(data.get("room_id", 0)) > 0)
	player_data.discovered_artifacts = p.artifacts.duplicate()
	player_data.active_artifacts = p.get("active_artifacts", p.artifacts).duplicate()
	player_data.fatal_shield_used = bool(p.get("fatal_shield_used", false))
	player_data.coin = int(p.coin)
	player_data.restore_upgrades(p.upgrades)
	player_data.restore_health(int(p.life), int(p.max_life), int(p.get("health_version", 1)))
	player_data.restore_healing_skill(p.get("healing_skill", {}))
	player_data.unlocked_skill = p.skills.duplicate()
	player_data.discovered_enemies = p.enemies.duplicate()
	player_data.discovered_artifacts = p.artifacts.duplicate()
	player_data.sync_bestiary_status()
