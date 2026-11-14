extends CanvasLayer
## All visual nodes and resources are authored in pause_menu.tscn.
@export_file("*.tscn") var leave_scene := "res://addons/maaacks_menus_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn"
var owns_pause := false
var previous_focus: Control
@onready var overlay: Control = $Overlay
@onready var menu: Control = $Overlay/MenuPanel
@onready var options: Control = $Overlay/OptionsPanel

func _ready() -> void:
	menu.get_node("ContinueButton").pressed.connect(resume)
	menu.get_node("OptionButton").pressed.connect(show_options)
	menu.get_node("RestartButton").pressed.connect(restart)
	menu.get_node("LeaveButton").pressed.connect(leave)
	options.get_node("BackButton").pressed.connect(back_to_pause)
	overlay.hide()
	options.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not get_tree().paused:
		open_pause()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if owns_pause and event.is_action_pressed("ui_cancel") and not event.is_echo():
		if options.visible:
			for dialog in options.find_children("*", "OverlaidWindow", true, false):
				if dialog.is_visible_in_tree():
					dialog.close()
					get_viewport().set_input_as_handled()
					return
			back_to_pause()
		else:
			resume()
		get_viewport().set_input_as_handled()

func open_pause() -> void:
	if owns_pause or get_tree().paused:
		return
	previous_focus = get_viewport().gui_get_focus_owner()
	owns_pause = true
	get_tree().paused = true
	overlay.show()
	back_to_pause()

func resume() -> void:
	if not owns_pause:
		return
	overlay.hide()
	options.hide()
	owns_pause = false
	get_tree().paused = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func show_options() -> void:
	menu.hide()
	options.show()
	options.get_node("BackButton").grab_focus()

func back_to_pause() -> void:
	options.hide()
	menu.show()
	menu.get_node("ContinueButton").grab_focus()

func restart() -> void:
	_change_scene.call_deferred(true)

func leave() -> void:
	_change_scene.call_deferred(false)

func _change_scene(reload_level: bool) -> void:
	if not owns_pause:
		return
	if not CheckpointManager.save_progress():
		return
	resume()
	if reload_level:
		player_data.restore_life()
	var error := get_tree().reload_current_scene() if reload_level else get_tree().change_scene_to_file(leave_scene)
	if error != OK:
		push_error("Tidak dapat mengganti scene: " + error_string(error))
		open_pause()

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false
