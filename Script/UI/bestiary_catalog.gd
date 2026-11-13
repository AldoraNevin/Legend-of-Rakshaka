@tool
extends Control
signal closed
@export_enum("Musuh", "Artefak") var initial_tab := 0:
	set(value):
		initial_tab = value
		if Engine.is_editor_hint() and is_node_ready():
			_set_category(initial_tab == 1)
## F6 shows authored content; the lobby always uses discovery progress.
@export var preview_all_when_run_alone := true
var was_paused := false
var previous_focus: Control
var owns_pause := false
var preview_mode := false
@onready var enemy_page: Control = $EnemyPage
@onready var artifact_page: Control = $ArtifactPage
var active_page: Control

func _ready() -> void:
	if Engine.is_editor_hint():
		_set_category(initial_tab == 1)
		return
	for tab in [enemy_page, artifact_page]:
		tab.category_requested.connect(_set_category)
		tab.close_requested.connect(close_book)
	hide()
	_open_standalone.call_deferred()

func _open_standalone() -> void:
	if get_tree().current_scene == self:
		preview_mode = preview_all_when_run_alone
		open_book(initial_tab == 1)

func open_book(show_artifacts: bool = false) -> void:
	if owns_pause:
		_set_category(show_artifacts)
		return
	previous_focus = get_viewport().gui_get_focus_owner()
	was_paused = get_tree().paused
	owns_pause = true
	get_tree().paused = true
	show()
	for tab in [enemy_page, artifact_page]:
		tab.search.text = ""
		tab.discovered.set_pressed_no_signal(false)
		tab.refresh_entries(preview_mode)
	_set_category(show_artifacts)
	active_page.close_button.grab_focus()

func _set_category(artifacts: bool) -> void:
	enemy_page.visible = not artifacts
	artifact_page.visible = artifacts
	active_page = artifact_page if artifacts else enemy_page

func close_book() -> void:
	if not owns_pause:
		return
	hide()
	get_tree().paused = was_paused
	owns_pause = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	closed.emit()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if owns_pause and event.is_action_pressed("ui_cancel"):
		close_book()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = was_paused
