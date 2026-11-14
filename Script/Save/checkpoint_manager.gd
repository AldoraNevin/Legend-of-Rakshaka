extends Node
signal checkpoints_changed
signal load_failed(message: String)
const ADAPTER := preload("res://Script/Save/room_checkpoint_adapter.gd")
const MAX_CHECKPOINTS := 3
const LOBBY := "res://Levels/lobby.tscn"
# Version 2 keeps stable slots; version 1 checkpoints remain readable.
var storage_path := "user://room_checkpoints.json"
var enabled := true
var loading := false
var active_slot := -1
var last_error := ""
var storage_error := ""
var last_room_instance := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player_data.progress_saver = save_progress
	get_tree().node_added.connect(_on_node_added)

func _exit_tree() -> void:
	player_data.progress_saver = Callable()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_progress()

func _on_node_added(node: Node) -> void:
	if enabled and ADAPTER.supports(node):
		_attach.call_deferred(node)

func _attach(stage: Node) -> void:
	if not is_instance_valid(stage) or not stage.is_inside_tree():
		return
	var rooms := stage.get_node_or_null("RoomRoot")
	if rooms == null:
		return
	rooms.child_entered_tree.connect(func(room: Node): _room_entered.call_deferred(stage, room))
	if is_instance_valid(stage.current_room):
		_room_entered(stage, stage.current_room)

func _room_entered(stage: Node, room: Node) -> void:
	if not enabled or loading or active_slot < 0 or not is_instance_valid(stage) or not is_instance_valid(room):
		return
	if stage.current_room != room or room.get_instance_id() == last_room_instance:
		return
	var data := ADAPTER.capture(stage)
	if not data.is_empty() and save_checkpoint(data):
		last_room_instance = room.get_instance_id()

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var value: Variant = parser.data
	if value is Dictionary:
		if value.get("version") == 2 and value.get("slots") is Array and value.slots.size() == MAX_CHECKPOINTS:
			return value
		if value.get("version") == 1 and value.get("checkpoints") is Array:
			var slots: Array = value.checkpoints.slice(0, MAX_CHECKPOINTS)
			slots.resize(MAX_CHECKPOINTS)
			return {"version": 2, "slots": slots}
	return {}

func list_checkpoints() -> Array:
	storage_error = ""
	var data := _read_file(storage_path)
	if data.is_empty():
		data = _read_file(storage_path + ".bak")
	if data.is_empty() and (FileAccess.file_exists(storage_path) or FileAccess.file_exists(storage_path + ".bak")):
		storage_error = "File save dan backup tidak dapat dibaca. Data tidak ditimpa."
	return data.get("slots", [null, null, null])

func checkpoint_error(value: Variant) -> String:
	if not value is Dictionary:
		return "Slot kosong atau save rusak."
	if value.get("scene") == LOBBY:
		if value.get("player") is Dictionary and value.get("saved_at") is String:
			return ADAPTER.player_error(value.player)
		return "Data pemain tidak lengkap."
	return ADAPTER.validation_error(value)

func latest_valid_index() -> int:
	var rows := list_checkpoints()
	var latest := -1
	for index in range(rows.size()):
		if checkpoint_error(rows[index]).is_empty():
			if latest < 0 or str(rows[index].saved_at) > str(rows[latest].saved_at):
				latest = index
	return latest

func _write_slots(rows: Array, replace_backup := false) -> bool:
	var temp := storage_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _save_error("Save gagal ditulis.")
	file.store_string(JSON.stringify({"version": 2, "slots": rows}, "\t"))
	file.flush()
	file.close()
	if _read_file(temp).is_empty():
		return _save_error("Verifikasi save gagal.")
	var backup := storage_path + ".bak"
	# Keep the good backup if the primary was corrupt and we recovered from it.
	if replace_backup:
		# Deletion must also clear the recovery copy so it cannot revive the slot.
		if DirAccess.copy_absolute(temp, backup) != OK:
			return _save_error("Backup save gagal diperbarui.")
	elif not _read_file(storage_path).is_empty():
		if DirAccess.copy_absolute(storage_path, backup) != OK:
			return _save_error("Backup save gagal.")
	if DirAccess.rename_absolute(temp, storage_path) != OK:
		return _save_error("Penyimpanan save gagal.")
	last_error = ""
	checkpoints_changed.emit()
	return true

func _save_error(message: String) -> bool:
	last_error = message
	push_error(message)
	load_failed.emit(message)
	return false

func save_checkpoint(data: Dictionary) -> bool:
	if active_slot < 0 or not enabled or loading:
		return false
	var error := checkpoint_error(data)
	if not error.is_empty():
		return _save_error(error)
	var rows := list_checkpoints()
	if not storage_error.is_empty():
		return _save_error(storage_error)
	rows[active_slot] = data
	return _write_slots(rows)

func save_progress() -> bool:
	# Running a scene directly in the editor never overwrites an arbitrary slot.
	if not enabled or loading or active_slot < 0:
		return true
	var rows := list_checkpoints()
	if not storage_error.is_empty():
		return _save_error(storage_error)
	if not rows[active_slot] is Dictionary:
		return _save_error("Slot aktif tidak tersedia.")
	var data: Dictionary = rows[active_slot].duplicate(true)
	data.player = ADAPTER.capture_player()
	data.saved_at = Time.get_datetime_string_from_system()
	return save_checkpoint(data)

func create_slot(index: int) -> bool:
	if loading or index < 0 or index >= MAX_CHECKPOINTS:
		return false
	var rows := list_checkpoints()
	if not storage_error.is_empty():
		return _fail(storage_error)
	if rows[index] != null:
		return _fail("Slot sudah terisi. Pilih Load untuk melanjutkan.")
	var previous := ADAPTER.capture_player()
	player_data.reset_progress()
	var data := {"version": 1, "scene": LOBBY, "room_label": "Lobby",
		"saved_at": Time.get_datetime_string_from_system(), "player": ADAPTER.capture_player()}
	rows[index] = data
	var saved := _write_slots(rows)
	ADAPTER.restore_player({"player": previous})
	if not saved:
		return false
	return load_checkpoint(index)

func delete_slot(index: int) -> bool:
	if loading or index < 0 or index >= MAX_CHECKPOINTS:
		return false
	var rows := list_checkpoints()
	if not storage_error.is_empty():
		return _fail(storage_error)
	rows[index] = null
	if not _write_slots(rows, true):
		return false
	if active_slot == index:
		active_slot = -1
		last_room_instance = 0
	return true

func continue_latest() -> bool:
	return load_checkpoint(latest_valid_index())

func load_checkpoint(index: int) -> bool:
	if loading:
		return false
	var rows := list_checkpoints()
	if not storage_error.is_empty():
		return _fail(storage_error)
	if index < 0 or index >= rows.size():
		return _fail("Slot save tidak tersedia.")
	var error := checkpoint_error(rows[index])
	if not error.is_empty():
		return _fail(error)
	loading = true
	_resume.call_deferred(rows[index].duplicate(true), index)
	return true

func _fail(message: String) -> bool:
	last_error = message
	loading = false
	load_failed.emit(message)
	return false

func _resume(data: Dictionary, slot: int) -> void:
	var packed := load(str(data.scene)) as PackedScene
	if packed == null:
		_fail("Scene checkpoint tidak dapat dimuat.")
		return
	var stage := packed.instantiate()
	var is_stage := ADAPTER.supports(stage)
	if not is_stage and str(data.scene) != LOBBY:
		stage.free()
		_fail("Generator level tidak lagi mendukung checkpoint ini.")
		return
	# Set exported inputs BEFORE _ready; the level builds its own room normally.
	if is_stage:
		stage.random_seed = int(data.seed)
		stage.preview_start_node = int(data.room_id)
	var previous_scene := get_tree().current_scene
	var previous_pause := get_tree().paused
	var old_state := {"player": ADAPTER.capture_player()}
	ADAPTER.restore_player(data)
	get_tree().paused = true
	get_tree().root.add_child(stage)
	if is_stage and (not is_instance_valid(stage.current_room) or int(stage.node_id) != int(data.room_id)):
		stage.queue_free()
		ADAPTER.restore_player(old_state)
		get_tree().paused = previous_pause
		_fail("Ruangan gagal dibangun. Save tetap tersimpan; mulai perjalanan baru jika level berubah.")
		return
	if is_stage:
		stage.rng.state = int(data.rng_state)
		stage.current_room_index = int(data.room_index)
		player_data.apply_player_stats(stage.player)
	active_slot = slot
	get_tree().current_scene = stage
	if is_instance_valid(previous_scene):
		previous_scene.queue_free()
	var music := get_node_or_null("/root/ProjectMusicController")
	if music != null:
		music.stop()
	last_room_instance = stage.current_room.get_instance_id() if is_stage else 0
	await get_tree().process_frame
	get_tree().paused = false
	loading = false
	last_error = ""
