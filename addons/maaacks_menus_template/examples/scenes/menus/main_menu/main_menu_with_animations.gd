extends MainMenu
## Main menu extension that animates the title and menu fading in.
## The animation can be skipped by the player with any input.

var animation_state_machine : AnimationNodeStateMachinePlayback

# --- VARIABEL KITA ---
@onready var mata_menyala = $bg/MataMenyala
# Gunakan get_node_or_null agar aman jika node belum siap sesaat
@onready var tombol_start = get_node_or_null("%NewGameButton")

func intro_done() -> void:
	animation_state_machine.travel("OpenMainMenu")

func _is_in_intro() -> bool:
	return animation_state_machine.get_current_node() == "Intro"

func _event_skips_intro(event : InputEvent) -> bool:
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _open_sub_menu(menu : PackedScene) -> Node:
	animation_state_machine.travel("OpenSubMenu")
	return super._open_sub_menu(menu)

func _close_sub_menu() -> void:
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event : InputEvent) -> void:
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)

func _ready() -> void:
	super._ready()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")
	
	if mata_menyala:
		mata_menyala.visible = false 
	
	if tombol_start:
		# 1. Sambungkan efek hover
		tombol_start.mouse_entered.connect(_on_new_game_mouse_entered)
		tombol_start.mouse_exited.connect(_on_new_game_mouse_exited)
		
		# 2. BAJAK SINYAL KLIK BAWAAN ADDON!
		# Ini akan otomatis memutus sambungan bawaan Maaacks Menus
		for sambungan in tombol_start.pressed.get_connections():
			tombol_start.pressed.disconnect(sambungan["callable"])
			
		# 3. Sambungkan ke fungsi animasi buatan kita
		tombol_start.pressed.connect(_on_new_game_animasi_pressed)

# ==========================================
# FUNGSI KUSTOM KITA DI BAWAH INI
# ==========================================

func _on_new_game_mouse_entered():
	if mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = true

func _on_new_game_mouse_exited():
	if mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = false

func _on_new_game_animasi_pressed():
	# 1. Matikan tombol agar tidak diklik dua kali
	tombol_start.disabled = true
	
	# 2. Animasi Kedip
	if mata_menyala:
		for i in range(4):
			mata_menyala.visible = true
			await get_tree().create_timer(0.1).timeout
			mata_menyala.visible = false
			await get_tree().create_timer(0.1).timeout
		
		mata_menyala.visible = true
		await get_tree().create_timer(0.5).timeout
	
	# 3. Animasi Fade Hitam & Fade Out Musik dengan Tween
	var fade_hitam = ColorRect.new()
	fade_hitam.color = Color(0, 0, 0, 0)
	fade_hitam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_hitam.z_index = 100 
	add_child(fade_hitam)
	
	var bgm = get_node_or_null("BackgroundMusicPlayer")
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true) # Perintah ini membuat animasi warna dan suara berjalan serentak!
	
	# Layar perlahan jadi hitam
	tween.tween_property(fade_hitam, "color:a", 1.0, 1.0) 
	
	# Musik perlahan mengecil sampai hilang (-80 dB)
	if bgm:
		tween.tween_property(bgm, "volume_db", -80.0, 1.0)
		
	await tween.finished
	
	# Matikan musik sepenuhnya setelah layarnya gelap total
	if bgm:
		bgm.stop()
	
	# 4. PINDAH SCENE
	# (Pastikan jalurnya sesuai dengan lokasi level aslimu)
	get_tree().change_scene_to_file("res://Levels/lobby.tscn")


func _on_new_game_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
