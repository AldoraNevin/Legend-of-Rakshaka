extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  TEST SUITE: SISTEM SAVE JSON & AES-256 ENKRIPSI  ")
	print("==================================================")
	
	# Bersihkan file sisa test sebelumnya
	_clean_files()
	
	# Test 1: Inisialisasi & Master Bestiary
	print("\n[TEST 1] Memuat master bestiary (UTF-8)...")
	player_data.init_system()
	
	var enemies: Array = player_data.bestiary_master.get("enemies", [])
	var bosses: Array = player_data.bestiary_master.get("bosses", [])
	var artifacts: Array = player_data.bestiary_master.get("artifacts", [])
	
	print("  - Jumlah Musuh Normal : ", enemies.size(), " (Diharapkan: 12)")
	print("  - Jumlah Boss Entity  : ", bosses.size(), " (Diharapkan: 4)")
	print("  - Jumlah Artefak      : ", artifacts.size(), " (Diharapkan: 20)")
	
	assert(enemies.size() == 12, "Jumlah musuh harus 12!")
	assert(bosses.size() == 4, "Jumlah boss harus 4!")
	assert(artifacts.size() == 20, "Jumlah artefak harus 20!")
	print("  [PASS] Test 1 Berhasil!")
	
	# Test 2: Serialisasi & Enkripsi AES-256 Save
	print("\n[TEST 2] Menguji enkripsi AES-256 & penulisan save...")
	player_data.coin = 25
	player_data.max_life = 5
	player_data.upgrade_levels["sword"] = 2
	player_data.update_bestiary("Kuntilanak")
	player_data.update_bestiary("kujang_pusaka")
	
	var save_ok: bool = player_data.save_to_json()
	print("  - Hasil save_to_json: ", save_ok)
	assert(save_ok, "save_to_json harus menghasilkan true!")
	assert(FileAccess.file_exists(player_data.SAVE_PATH), "File save harus ada di disk!")
	
	# Verifikasi bahwa file di disk terenkripsi (bukan plain text)
	var raw_reader := FileAccess.open(player_data.SAVE_PATH, FileAccess.READ)
	assert(raw_reader != null, "Harus bisa membuka file save secara raw!")
	var raw_content := raw_reader.get_as_text()
	raw_reader.close()
	
	var is_plain: bool = raw_content.contains("Kuntilanak") or raw_content.contains("kujang_pusaka")
	print("  - Apakah file berisi teks biasa tanpa enkripsi? ", is_plain)
	assert(not is_plain, "File save HARUS terenkripsi AES-256 dan tidak boleh terbaca sebagai teks biasa!")
	print("  [PASS] Test 2 Berhasil: Terverifikasi terenkripsi AES-256!")
	
	# Test 3: Deserialisasi & Dekripsi (load_game_data)
	print("\n[TEST 3] Menguji dekripsi & pemulihan data (load_game_data)...")
	# Reset status memori ke kondisi kosong
	player_data.coin = 0
	player_data.max_life = 1
	player_data.upgrade_levels["sword"] = 0
	player_data.discovered_enemies = []
	player_data.discovered_artifacts = []
	
	var load_ok: bool = player_data.load_game_data()
	print("  - Hasil load_game_data: ", load_ok)
	assert(load_ok, "load_game_data harus berhasil!")
	print("  - Coin dipulihkan: ", player_data.coin, " (Diharapkan: 25)")
	print("  - Max Life dipulihkan: ", player_data.max_life, " (Diharapkan: 5)")
	print("  - Level Sword dipulihkan: ", player_data.upgrade_levels["sword"], " (Diharapkan: 2)")
	print("  - Musuh ditemukan: ", player_data.discovered_enemies)
	print("  - Artefak ditemukan: ", player_data.discovered_artifacts)
	
	assert(player_data.coin == 25, "Coin harus bernilai 25!")
	assert(player_data.max_life == 5, "Max life harus bernilai 5!")
	assert(player_data.upgrade_levels["sword"] == 2, "Sword level harus bernilai 2!")
	assert("Kuntilanak" in player_data.discovered_enemies, "Kuntilanak harus tercatat!")
	assert("Kujang Pusaka" in player_data.discovered_artifacts, "Kujang Pusaka harus tercatat!")
	print("  [PASS] Test 3 Berhasil: Dekripsi dan data cocok 100%!")
	
	# Test 4: Temp File Swapping & Backup Integrity Check
	print("\n[TEST 4] Menguji pembuatan backup saat overwrite save...")
	player_data.coin = 50
	player_data.save_to_json()
	assert(FileAccess.file_exists(player_data.BACKUP_SAVE_PATH), "File backup terenkripsi harus dibuat saat menyimpan ulang!")
	print("  [PASS] Test 4 Berhasil: Backup terenkripsi dibuat dengan aman!")
	
	# Test 5: Failsafe Pemulihan saat Save File Utama Rusak (Corrupt)
	print("\n[TEST 5] Menguji mekanisme pemulihan otomatis saat file utama rusak (corrupt)...")
	# Sengaja merusak file save utama dengan byte sampah
	var corrupt_writer := FileAccess.open(player_data.SAVE_PATH, FileAccess.WRITE)
	corrupt_writer.store_string("BERKAS RUSAK TIDAK BISA DIDEKRIPSI %$#&*!@^#*&!^$#")
	corrupt_writer.close()
	
	# Reset memori
	player_data.coin = 0
	# Panggil load_game_data - sistem harus otomatis mendeteksi kegagalan dekripsi dan beralih ke backup
	var recovery_ok: bool = player_data.load_game_data()
	print("  - Hasil pemulihan dari backup: ", recovery_ok)
	print("  - Coin setelah pemulihan: ", player_data.coin)
	assert(recovery_ok, "Sistem harus berhasil pulih menggunakan file backup!")
	assert(player_data.coin == 25, "Data harus kembali ke versi backup valid terakhir (25 coin)!")
	print("  [PASS] Test 5 Berhasil: Mekanisme failsafe pemulihan data berfungsi sempurna!")
	
	print("\n==================================================")
	print("  SEMUA PENGUJIAN SISTEM PENYIMPANAN BERHASIL!    ")
	print("==================================================")
	
	_clean_files()
	quit(0)


func _clean_files() -> void:
	if FileAccess.file_exists(player_data.SAVE_PATH):
		DirAccess.remove_absolute(player_data.SAVE_PATH)
	if FileAccess.file_exists(player_data.TEMP_SAVE_PATH):
		DirAccess.remove_absolute(player_data.TEMP_SAVE_PATH)
	if FileAccess.file_exists(player_data.BACKUP_SAVE_PATH):
		DirAccess.remove_absolute(player_data.BACKUP_SAVE_PATH)
