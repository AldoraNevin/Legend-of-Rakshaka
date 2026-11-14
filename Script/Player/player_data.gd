extends Node2D
class_name player_data

# ==============================================================================
# KONFIGURASI PENYIMPANAN & ENKRIPSI AES-256 (Standar C4, C5, C6 & RS-M06/RS-M08)
# ==============================================================================
const SAVE_PATH := "user://player_Save.json"
const TEMP_SAVE_PATH := "user://player_Save.json.tmp"
const BACKUP_SAVE_PATH := "user://player_Save.json.bak"
const BESTIARY_DATA_PATH := "res://Data/bestiary_data.json"
const ENCRYPTION_KEY := "RakshakaNusantaraKey2026AES256"

# ==============================================================================
# DATA STATUS KARAKTER (Tabel 2.2 Struktur Data Player Save)
# ==============================================================================
static var player_id: String = "Saka_01"
static var coin: int = 0
const MAX_HEALTH := 100
const HEALTH_VERSION := 2

static var life: int = MAX_HEALTH
static var max_life: int = MAX_HEALTH
static var last_played: String = ""

static var upgrade_levels: Dictionary = {
	"max_life": 0,
	"speed": 0,
	"jump": 0,
	"sword": 0,
}

static var unlocked_skill: Array = []
static var discovered_enemies: Array = []
static var discovered_artifacts: Array = []

static var bestiary_master: Dictionary = {
	"enemies": [],
	"bosses": [],
	"artifacts": []
}

static var progress_saver: Callable

static var _is_initialized: bool = false

const UPGRADE_DATA = {
	"max_life": {
		"name": "Vitalitas",
		"description": "Kurangi damage masuk 5% per level; pulihkan HP.",
		"base_cost": 3,
		"max_level": 3,
	},
	"speed": {
		"name": "Gerak Ringan",
		"description": "Tambah kecepatan jalan.",
		"base_cost": 2,
		"max_level": 3,
	},
	"jump": {
		"name": "Lompatan",
		"description": "Tambah kekuatan lompat.",
		"base_cost": 2,
		"max_level": 3,
	},
	"sword": {
		"name": "Tebasan",
		"description": "Tambah damage pedang.",
		"base_cost": 4,
		"max_level": 2,
	},
}


static func _static_init() -> void:
	init_system()


static func init_system() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	load_bestiary_master()
	sync_bestiary_status()


# ==============================================================================
# SISTEM FILE JSON & ENKRIPSI AES-256 (RS-M06 & RS-M08)
# ==============================================================================

## RS-M06: Menserialisasi data atribut kelas pemain dan menyimpannya
## dengan enkripsi AES-256 serta mekanisme atomic temp-file swapping (failsafe).
static func save_to_json() -> bool:
	if progress_saver.is_valid():
		return progress_saver.call()
	last_played = Time.get_datetime_string_from_system()

	var save_dict: Dictionary = {
		"player_id": player_id,
		"exp_point": coin,
		"coin": coin,
		"health_version": HEALTH_VERSION,
		"player_hp": max_life,
		"max_life": max_life,
		"upgrade_levels": upgrade_levels.duplicate(true),
		"unlocked_skill": unlocked_skill.duplicate(true),
		"discovered_enemies": discovered_enemies.duplicate(true),
		"discovered_artifacts": discovered_artifacts.duplicate(true),
		"last_played": last_played
	}

	var json_string := JSON.stringify(save_dict, "\t")

	# 1. Tulis ke file sementara dengan enkripsi AES-256
	var temp_file := FileAccess.open_encrypted_with_pass(TEMP_SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if temp_file == null:
		push_error("Gagal membuka file sementara untuk enkripsi save: %s" % error_string(FileAccess.get_open_error()))
		return false

	temp_file.store_string(json_string)
	temp_file.flush()
	temp_file.close()

	# 2. Validasi integritas file sementara (100% check sebelum menimpa file utama)
	var verify_file := FileAccess.open_encrypted_with_pass(TEMP_SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if verify_file == null:
		push_error("Verifikasi baca file sementara terenkripsi gagal!")
		_remove_file(TEMP_SAVE_PATH)
		return false

	var verify_text := verify_file.get_as_text()
	verify_file.close()

	var parsed_check: Variant = JSON.parse_string(verify_text)
	if typeof(parsed_check) != TYPE_DICTIONARY or not (parsed_check as Dictionary).has("player_id"):
		push_error("Verifikasi JSON berkas sementara tidak valid (data corrupt)!")
		_remove_file(TEMP_SAVE_PATH)
		return false

	# 3. Buat backup dari save utama saat ini jika ada
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_SAVE_PATH)

	# 4. Terapkan file sementara ke save utama (Atomic Swap)
	var copy_err := DirAccess.copy_absolute(TEMP_SAVE_PATH, SAVE_PATH)
	_remove_file(TEMP_SAVE_PATH)

	if copy_err != OK:
		push_error("Gagal menyalin file sementara ke save file utama: %s" % error_string(copy_err))
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			DirAccess.copy_absolute(BACKUP_SAVE_PATH, SAVE_PATH)
		return false

	return true


## RS-M08: Melakukan deserialisasi berkas JSON terenkripsi untuk memulihkan progres pemain terakhir.
static func load_game_data() -> bool:
	var path_to_load := SAVE_PATH

	if not FileAccess.file_exists(path_to_load):
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			path_to_load = BACKUP_SAVE_PATH
		else:
			# Belum ada file simpanan, inisialisasi default
			sync_bestiary_status()
			return false

	var file := FileAccess.open_encrypted_with_pass(path_to_load, FileAccess.READ, ENCRYPTION_KEY)
	var success := false
	var parsed_data: Variant = null

	if file != null:
		var text := file.get_as_text()
		file.close()
		parsed_data = JSON.parse_string(text)
		if typeof(parsed_data) == TYPE_DICTIONARY:
			success = true

	# Failsafe: Jika file save utama corrupt, coba pulihkan dari backup terenkripsi terakhir
	if not success and path_to_load == SAVE_PATH and FileAccess.file_exists(BACKUP_SAVE_PATH):
		push_warning("Berkas save utama corrupt! Mencoba memulihkan dari backup terenkripsi...")
		var backup_file := FileAccess.open_encrypted_with_pass(BACKUP_SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
		if backup_file != null:
			var backup_text := backup_file.get_as_text()
			backup_file.close()
			parsed_data = JSON.parse_string(backup_text)
			if typeof(parsed_data) == TYPE_DICTIONARY:
				success = true
				DirAccess.copy_absolute(BACKUP_SAVE_PATH, SAVE_PATH)

	if success and parsed_data != null:
		_apply_loaded_dict(parsed_data as Dictionary)
		sync_bestiary_status()
		return true
	else:
		push_error("Gagal membaca save file dan backup terenkripsi.")
		sync_bestiary_status()
		return false


static func _apply_loaded_dict(data: Dictionary) -> void:
	player_id = data.get("player_id", player_id)
	coin = data.get("coin", data.get("exp_point", coin))
	max_life = MAX_HEALTH
	life = max_life

	var loaded_upgrades = data.get("upgrade_levels", {})
	if typeof(loaded_upgrades) == TYPE_DICTIONARY:
		for k in (loaded_upgrades as Dictionary).keys():
			if upgrade_levels.has(k):
				upgrade_levels[k] = loaded_upgrades[k]

	var loaded_skills = data.get("unlocked_skill", [])
	if typeof(loaded_skills) == TYPE_ARRAY:
		unlocked_skill = loaded_skills

	var loaded_enemies = data.get("discovered_enemies", [])
	if typeof(loaded_enemies) == TYPE_ARRAY:
		discovered_enemies = loaded_enemies

	var loaded_artifacts = data.get("discovered_artifacts", [])
	if typeof(loaded_artifacts) == TYPE_ARRAY:
		discovered_artifacts = loaded_artifacts

	last_played = data.get("last_played", "")


# ==============================================================================
# SISTEM MASTER BESTIARY & KATALOG MITOLOGI (RS-M05, Standar C5)
# ==============================================================================

## Membaca basis data master bestiary_data.json dalam format UTF-8
static func load_bestiary_master() -> void:
	if not FileAccess.file_exists(BESTIARY_DATA_PATH):
		push_warning("File master bestiary tidak ditemukan di: %s" % BESTIARY_DATA_PATH)
		return

	var file := FileAccess.open(BESTIARY_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Gagal membuka master bestiary: %s" % error_string(FileAccess.get_open_error()))
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		bestiary_master = parsed as Dictionary
	else:
		push_error("Format JSON pada master bestiary tidak valid!")


## Sinkronisasi status is_unlocked pada data master dengan array simpanan pemain
static func sync_bestiary_status() -> void:
	for enemy in bestiary_master.get("enemies", []):
		var id: String = enemy.get("entity_id", "")
		var nama: String = enemy.get("name", "")
		enemy["is_unlocked"] = (nama in discovered_enemies or id in discovered_enemies)

	for boss in bestiary_master.get("bosses", []):
		var id: String = boss.get("entity_id", "")
		var nama: String = boss.get("name", "")
		boss["is_unlocked"] = (nama in discovered_enemies or id in discovered_enemies)

	for art in bestiary_master.get("artifacts", []):
		var id: String = art.get("entity_id", "")
		var nama: String = art.get("name", "")
		art["is_unlocked"] = (nama in discovered_artifacts or id in discovered_artifacts)


## RS-M05: Memperbarui data bestiary saat menemukan musuh atau artefak baru lalu menyimpan otomatis
static func update_bestiary(entity_id: String) -> void:
	init_system()
	entity_id = entity_id.strip_edges()
	var target_lower := entity_id.to_lower()
	var found := false

	# Periksa musuh biasa
	for item in bestiary_master.get("enemies", []):
		if item.get("entity_id", "").to_lower() == target_lower or item.get("name", "").to_lower() == target_lower:
			item["is_unlocked"] = true
			if item["name"] not in discovered_enemies:
				discovered_enemies.append(item["name"])
			found = true
			break

	# Periksa boss
	if not found:
		for item in bestiary_master.get("bosses", []):
			if item.get("entity_id", "").to_lower() == target_lower or item.get("name", "").to_lower() == target_lower:
				item["is_unlocked"] = true
				if item["name"] not in discovered_enemies:
					discovered_enemies.append(item["name"])
				found = true
				break

	# Periksa artefak
	if not found:
		for item in bestiary_master.get("artifacts", []):
			if item.get("entity_id", "").to_lower() == target_lower or item.get("name", "").to_lower() == target_lower:
				item["is_unlocked"] = true
				if item["name"] not in discovered_artifacts:
					discovered_artifacts.append(item["name"])
				found = true
				break

	if not found:
		if entity_id not in discovered_enemies:
			discovered_enemies.append(entity_id)

	save_to_json()


static func discover_enemy(enemy_name: String) -> void:
	update_bestiary(enemy_name)


static func discover_artifact(artifact_name: String) -> void:
	update_bestiary(artifact_name)


# ==============================================================================
# RS-M04: SIKLUS ROGUELIKE LOOP
# ==============================================================================

## Menjalankan siklus penalti saat karakter mati: reset nyawa, auto-save resource,
## dan memuat ulang scene Lobi.
static func execute_roguelike_loop(caller: Node = null) -> void:
	restore_life()
	save_to_json()

	if caller != null and caller.is_inside_tree():
		if caller.has_node("/root/SceneLoader"):
			caller.get_node("/root/SceneLoader").call("load_scene", "res://Levels/lobby.tscn")
		else:
			caller.get_tree().change_scene_to_file("res://Levels/lobby.tscn")


# ==============================================================================
# FUNGSI UPGRADE & STATS PEMAIN
# ==============================================================================

static func get_upgrade_cost(upgrade_id: String) -> int:
	if not UPGRADE_DATA.has(upgrade_id):
		return 0

	var level: int = upgrade_levels.get(upgrade_id, 0)
	var base_cost: int = UPGRADE_DATA[upgrade_id]["base_cost"]
	return base_cost * (level + 1)


static func get_upgrade_name(upgrade_id: String) -> String:
	if not UPGRADE_DATA.has(upgrade_id):
		return upgrade_id

	return UPGRADE_DATA[upgrade_id]["name"]


static func can_upgrade(upgrade_id: String) -> bool:
	if not UPGRADE_DATA.has(upgrade_id):
		return false

	var level: int = upgrade_levels.get(upgrade_id, 0)
	var max_level: int = UPGRADE_DATA[upgrade_id]["max_level"]
	return level < max_level and coin >= get_upgrade_cost(upgrade_id)


static func buy_upgrade(upgrade_id: String) -> bool:
	if not can_upgrade(upgrade_id):
		return false

	coin -= get_upgrade_cost(upgrade_id)
	upgrade_levels[upgrade_id] = upgrade_levels.get(upgrade_id, 0) + 1

	if upgrade_id == "max_life":
		max_life = MAX_HEALTH
		life = max_life

	save_to_json()
	return true


static func restore_life() -> void:
	life = max_life


static func apply_player_stats(player) -> void:
	player.speed = 100.0 + upgrade_levels["speed"] * 15.0
	player.jump_force = 300.0 + upgrade_levels["jump"] * 20.0
	player.sword_damage = 1 + upgrade_levels["sword"]
	player.max_jump = max(player.max_jump, 2)


static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func reset_progress() -> void:
	coin = 0
	max_life = MAX_HEALTH
	life = MAX_HEALTH
	last_played = ""
	for key in upgrade_levels:
		upgrade_levels[key] = 0
	unlocked_skill = []
	discovered_enemies = []
	discovered_artifacts = []
	sync_bestiary_status()

static func add_gold(amount: int) -> void:
	coin = maxi(0, coin + amount)
	save_to_json()


static func restore_health(saved_life: int, saved_max: int, version: int) -> void:
	max_life = MAX_HEALTH
	if version < HEALTH_VERSION:
		# Older saves used hearts (4 + upgrades); preserve their health percentage.
		life = clampi(roundi(float(saved_life) / maxi(1, saved_max) * MAX_HEALTH), 1, MAX_HEALTH)
	else:
		life = clampi(saved_life, 1, MAX_HEALTH)

static func incoming_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var reduction := clampi(int(upgrade_levels.get("max_life", 0)), 0, 3) * 0.05
	return maxi(1, roundi(amount * (1.0 - reduction)))
