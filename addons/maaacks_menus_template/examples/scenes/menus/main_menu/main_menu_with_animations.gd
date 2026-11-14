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
	if CheckpointManager.loading:
		return
	super._input(event)

func _ready() -> void:
	super._ready()
	# Keep menu music scene-owned; autoplay lets the global controller preserve it.
	$BackgroundMusicPlayer.play()
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
			
		# 3. Start Game membuka pemilihan slot save
		tombol_start.pressed.connect(_open_load_menu)

# ==========================================
# FUNGSI KUSTOM KITA DI BAWAH INI
# ==========================================

func _on_new_game_mouse_entered():
	if mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = true

func _on_new_game_mouse_exited():
	if mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = false

func _open_load_menu() -> void:
	if mata_menyala:
		mata_menyala.visible = false
	_open_sub_menu(preload("res://Scenes/UI/load_game_menu.tscn"))
