extends MainMenu
## Main menu extension that animates the title and menu fading in.
## The animation can be skipped by the player with any input.

var animation_state_machine : AnimationNodeStateMachinePlayback
var departing := false
var departure_layer: CanvasLayer
var departure_fade: ColorRect
var menu_music_volume := 0.0


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
	if sub_menu == null:
		return
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event : InputEvent) -> void:
	if departing:
		get_viewport().set_input_as_handled()
		return
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
	menu_music_volume = $BackgroundMusicPlayer.volume_db
	CheckpointManager.load_failed.connect(_departure_failed)
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
	if not departing and mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = true

func _on_new_game_mouse_exited():
	if not departing and mata_menyala and not tombol_start.disabled:
		mata_menyala.visible = false

func _open_load_menu() -> void:
	if departing or CheckpointManager.loading:
		return
	if mata_menyala:
		mata_menyala.visible = false
	var slots := _open_sub_menu(preload("res://Scenes/UI/load_game_menu.tscn"))
	slots.slot_selected.connect(_start_departure, CONNECT_DEFERRED)


func _start_departure(index: int, is_empty: bool) -> void:
	if departing or CheckpointManager.loading:
		return
	departing = true
	_close_sub_menu()
	# Block mouse/touch as well as keyboard throughout the cinematic.
	departure_layer = CanvasLayer.new()
	departure_layer.layer = 120
	add_child(departure_layer)
	departure_fade = ColorRect.new()
	departure_fade.color = Color(0, 0, 0, 0)
	departure_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	departure_layer.add_child(departure_fade)
	departure_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	await get_tree().create_timer(0.45).timeout
	mata_menyala.show()
	mata_menyala.modulate.a = 0.0
	var blink := create_tween()
	for cycle in range(4):
		blink.tween_property(mata_menyala, "modulate:a", 1.0, 0.12)
		blink.tween_interval(0.09)
		blink.tween_property(mata_menyala, "modulate:a", 0.0, 0.12)
		blink.tween_interval(0.07)
	blink.tween_property(mata_menyala, "modulate:a", 1.0, 0.12)
	await blink.finished
	var fade := create_tween().set_parallel(true)
	fade.tween_property(departure_fade, "color:a", 1.0, 0.65)
	fade.tween_property($BackgroundMusicPlayer, "volume_db", -60.0, 0.65)
	await fade.finished
	# Loading starts only after the last black frame is rendered.
	await get_tree().process_frame
	var success := CheckpointManager.create_slot(index) if is_empty else CheckpointManager.load_checkpoint(index)
	if not success and departing:
		_departure_failed(CheckpointManager.last_error)

func _departure_failed(message: String) -> void:
	if not departing:
		return
	departing = false
	if is_instance_valid(departure_layer):
		departure_layer.queue_free()
	mata_menyala.hide()
	mata_menyala.modulate.a = 1.0
	$BackgroundMusicPlayer.volume_db = menu_music_volume
	_open_load_menu()
	if is_instance_valid(sub_menu):
		sub_menu._on_failed(message)
