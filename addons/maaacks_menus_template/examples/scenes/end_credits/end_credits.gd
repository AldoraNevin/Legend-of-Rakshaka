@tool
extends "res://addons/maaacks_menus_template/examples/scenes/credits/scrolling_credits.gd"

## Defines the path to the main menu. Hides the Main Menu button if not set.
## Will attempt to read from AppConfig if left empty.
@export_file("*.tscn") var main_menu_scene_path : String
## This option forces the mouse to be visible when the menu shows up.
## Useful for games that capture the mouse, and don't automatically return it.
@export var force_mouse_mode_visible : bool = false

var returning_to_lobby := false

@onready var end_message_panel = %EndMessagePanel
@onready var exit_button = %ExitButton
@onready var menu_button = %MenuButton
@onready var init_mouse_filter : MouseFilter = mouse_filter

func get_main_menu_scene_path() -> String:
	if main_menu_scene_path.is_empty():
		return AppConfig.main_menu_scene_path
	return main_menu_scene_path

func _end_reached() -> void:
	if returning_to_lobby:
		return
	returning_to_lobby = true
	super._end_reached()
	scroll_container.hide()
	create_tween().tween_property($EndingFilm, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	$EndingFilm.paused = false

func _return_to_lobby() -> void:
	get_tree().change_scene_to_file.call_deferred("res://Levels/lobby.tscn")

# ScrollContainer clamps at its maximum; reaching that value completes the roll.
func is_end_reached() -> bool:
	var bar := scroll_container.get_v_scroll_bar()
	return bar.max_value > bar.page and scroll_container.scroll_vertical >= floori(bar.max_value - bar.page)

func load_main_menu() -> void:
	SceneLoader.load_scene(get_main_menu_scene_path())

func exit_game() -> void:
	if OS.has_feature("web"):
		load_main_menu()
	get_tree().quit()

func _on_visibility_changed() -> void:
	if visible:
		end_message_panel.hide()
		mouse_filter = init_mouse_filter
	super._on_visibility_changed()

func set_header_and_footer() -> void:
	super.set_header_and_footer()
	header_space.custom_minimum_size.y = size.y * 0.14

func _ready() -> void:
	if get_main_menu_scene_path().is_empty():
		menu_button.hide()
	if OS.has_feature("web"):
		exit_button.hide()
	end_message_panel.hide()
	super._ready()
	scroll_container.z_index = 2
	$EndingFilm.z_index = 1
	if not Engine.is_editor_hint():
		$EndingFilm.finished.connect(_return_to_lobby)
		$EndingFilm.play()

func _process(delta: float) -> void:
	super._process(delta)
	# Reserve the closing sequence if the player pauses or rewinds the text.
	if not Engine.is_editor_hint() and not returning_to_lobby and $EndingFilm.stream_position >= 340.0:
		$EndingFilm.paused = true

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_released("ui_cancel"):
		if not returning_to_lobby:
			_end_reached()
		else:
			_return_to_lobby()

func _on_exit_button_pressed():
	exit_game()

func _on_menu_button_pressed():
	load_main_menu()
