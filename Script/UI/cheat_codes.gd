extends Node
## Movement and invulnerability flags are session-only; artifact unlocks persist.
var double_jump := false
var god_mode := false
const ADAPTER = preload("res://Script/Save/room_checkpoint_adapter.gd")
const DESTINATIONS = {"TUTORIAL": 0, "ROOM1": 1, "ROOM2": 2, "ROOM3": 3,
	"ROOM4": 4, "ROOM5": 5, "BOSS": 6}

func execute(raw: String) -> String:
	var words := raw.strip_edges().to_upper().split(" ", false)
	if words.is_empty():
		return "Masukkan kode terlebih dahulu."
	var code: String = words[0]
	if code in ["DOUBLEJUMP", "GODMODE"]:
		if words.size() > 2 or (words.size() == 2 and words[1] not in ["ON", "OFF"]):
			return "Gunakan %s ON atau %s OFF." % [code, code]
		var enabled: bool = words.size() == 1 or words[1] == "ON"
		if code == "DOUBLEJUMP":
			double_jump = enabled
			for player in get_tree().get_nodes_in_group("player"):
				if player.has_method("refresh_jump_ability"):
					player.refresh_jump_ability()
		else:
			god_mode = enabled
		return "%s %s." % [code, "aktif" if enabled else "nonaktif"]
	if code == "ALLARTIFACTS":
		if words.size() != 1:
			return "Gunakan ALLARTIFACTS tanpa tambahan."
		return unlock_all_artifacts()
	if words.size() != 1 or not DESTINATIONS.has(code):
		return "Kode tidak dikenal. Lihat daftar kode di atas."
	var stage := get_tree().current_scene
	if stage == null or not ADAPTER.supports(stage):
		return "Masuk stage melalui lobby dahulu, lalu gunakan kode tujuan."
	if CheckpointManager.loading:
		return "Tunggu proses load selesai."
	if player_data.life <= 0 or stage.player.is_dead:
		return "Pemain sudah mati. Restart dahulu."
	var target: int = DESTINATIONS[code]
	if not stage.templates.has(target):
		return "Ruangan tujuan belum tersedia."
	if RoomLoading.busy:
		return "Tunggu proses loading selesai."
	stage.travel_to_room.call_deferred(target)
	return "Memuat %s. Setelah selesai, tekan Back lalu Continue." % stage.stage_graph[target].label



func unlock_all_artifacts() -> String:
	if CheckpointManager.loading:
		return "Tunggu proses load selesai."
	player_data.init_system()
	var artifacts: Array = player_data.bestiary_master.get("artifacts", [])
	if artifacts.is_empty():
		return "Data artefak belum tersedia."
	for artifact in artifacts:
		var artifact_name: String = artifact.get("name", "")
		if not artifact_name.is_empty() and artifact_name not in player_data.active_artifacts:
			player_data.active_artifacts.append(artifact_name)
		if not artifact_name.is_empty() and artifact_name not in player_data.discovered_artifacts:
			player_data.discovered_artifacts.append(artifact_name)
	player_data.sync_bestiary_status()
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("refresh_artifact_stats"):
			player.refresh_artifact_stats()
	if not player_data.save_to_json():
		return "Semua artefak terbuka, tetapi save gagal. Coba lagi."
	if not CheckpointManager.enabled or CheckpointManager.active_slot < 0:
		return "Semua artefak terbuka untuk sesi ini (tidak ada slot save aktif)."
	return "Semua artefak terbuka dan tersimpan di slot aktif."
