extends Node
## Session-only flags. Never grant artifacts or save these flags to the profile.
var double_jump := false
var god_mode := false
const ADAPTER = preload("res://Script/Save/room_checkpoint_adapter.gd")
const DESTINATIONS = {"TUTORIAL": 0, "ROOM1": 1, "ROOM2": 2, "ROOM3": 3,
	"ELITE": 4, "ROOM4": 5, "ROOM5": 6, "ROOM6": 7, "BOSS": 8}

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
	stage.stage_finished = false
	stage.node_id = target
	stage.current_room_index = target
	stage.load_next_room()
	if not is_instance_valid(stage.current_room):
		return "Ruangan gagal dibuat. Periksa Output Godot."
	stage.player.velocity = Vector2.ZERO
	return "Berpindah ke %s. Tekan Back lalu Continue." % stage.stage_graph[target].label
