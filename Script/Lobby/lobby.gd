extends Node2D

const LEVEL_1_SCENE := "res://Levels/stage_graph_template.tscn"

var travel_pending := false
var current_interactable = null
var bestiary_catalog: Control

@onready var prompt_panel: Panel = $LobbyUI/PromptPanel
@onready var prompt_label: Label = $LobbyUI/PromptPanel/PromptLabel
@onready var info_panel: Panel = $LobbyUI/InfoPanel
@onready var info_title: Label = $LobbyUI/InfoPanel/Title
@onready var info_body: Label = $LobbyUI/InfoPanel/Body
var upgrade_panel: Control



func _ready() -> void:
	# Keep this track owned by the lobby so it stops when leaving the scene.
	ProjectMusicController.stop()
	preload("res://Script/Audio/game_audio.gd").configure_music($LobbyMusic, true)
	bestiary_catalog = preload("res://Scenes/Interactables/bestiary_catalog.tscn").instantiate()
	$LobbyUI.add_child(bestiary_catalog)
	$LobbyUI.visible = true
	$LobbyUI.show()
	player_data.restore_life()
	prompt_panel.hide()
	info_panel.hide()
	$LobbyUI/UpgradePanel.hide()
	var upgrade_layer := CanvasLayer.new()
	upgrade_layer.layer = 120
	add_child(upgrade_layer)
	upgrade_panel = preload("res://Script/UI/upgrade_menu.gd").new()
	upgrade_layer.add_child(upgrade_panel)
	upgrade_panel.hide()

	$LobbyUI/InfoPanel/CloseButton.pressed.connect(close_panels)

	refresh_upgrade_panel()


func _unhandled_input(event: InputEvent) -> void:
	var is_interact := event.is_action_pressed("ui_interact")

	if is_interact and current_interactable != null:
		current_interactable.activate(self)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		close_panels()


func set_current_interactable(interactable) -> void:
	current_interactable = interactable
	$LobbyUI.visible = true
	$LobbyUI.show()
	prompt_label.text = "[E] " + interactable.title
	prompt_panel.show()


func clear_current_interactable(interactable) -> void:
	if current_interactable != interactable:
		return

	current_interactable = null
	prompt_panel.hide()


func open_message_panel(title: String, body: String) -> void:
	close_panels()
	info_title.text = title
	info_body.text = body
	info_panel.show()


func open_upgrade_panel() -> void:
	close_panels()
	refresh_upgrade_panel()
	upgrade_panel.open_menu()


func open_bestiary_panel() -> void:
	close_panels()
	bestiary_catalog.open_book()


func open_artifact_panel() -> void:
	close_panels()
	bestiary_catalog.open_book(true)


func travel_to_scene(scene_path: String) -> void:
	if travel_pending:
		return
	travel_pending = true
	if scene_path.is_empty():
		scene_path = LEVEL_1_SCENE

	call_deferred("_change_to_scene", scene_path)


func _change_to_scene(scene_path: String) -> void:
	if not is_inside_tree():
		return

	var error: int = await RoomLoading.change_scene(scene_path)
	if error != OK:
		travel_pending = false
		open_message_panel("Stage gagal dimuat", "Kode error: %s. Coba kembali melalui portal." % error_string(error))


func close_panels() -> void:
	if is_instance_valid(bestiary_catalog):
		bestiary_catalog.close_book()
	info_panel.hide()
	upgrade_panel.hide()


func refresh_upgrade_panel() -> void:
	upgrade_panel.refresh()


func _format_entries(entries: Array) -> String:
	var lines: Array = []
	for entry in entries:
		lines.append("- " + str(entry))
	return "\n".join(lines)


func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	if player_data.buy_upgrade(upgrade_id):
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			player_data.apply_player_stats(player)
		refresh_upgrade_panel()
