extends CanvasLayer
## --touch-controls enables desktop preview without changing keyboard controls.
var buttons: Array[TouchScreenButton] = []
var enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or "--touch-controls" in OS.get_cmdline_user_args()
	for child in $Buttons.get_children():
		if child is TouchScreenButton:
			buttons.append(child)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_update_visibility()

func _process(_delta: float) -> void:
	_update_visibility()

func _update_visibility() -> void:
	var show_controls := enabled and not get_tree().paused
	if $Buttons.visible and not show_controls:
		_release_actions()
	$Buttons.visible = show_controls

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	$Buttons/Left.position = Vector2(80, size.y - 90)
	$Buttons/Right.position = Vector2(200, size.y - 90)
	$Buttons/Jump.position = size - Vector2(80, 90)
	$Buttons/Attack.position = size - Vector2(200, 90)
	$Buttons/Dash.position = size - Vector2(80, 215)
	$Buttons/Interact.position = size - Vector2(200, 215)
	$Buttons/Pause.position = Vector2(size.x - 65, 65)

func _release_actions() -> void:
	for button in buttons:
		if button.is_pressed():
			Input.action_release(button.action)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_actions()

func _exit_tree() -> void:
	_release_actions()
