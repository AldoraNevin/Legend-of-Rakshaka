extends Node2D

const LEVEL_1_SCENE := "res://Levels/stage_graph_template.tscn"

var current_interactable = null
var bestiary_catalog: Control

@onready var prompt_panel: Panel = $LobbyUI/PromptPanel
@onready var prompt_label: Label = $LobbyUI/PromptPanel/PromptLabel
@onready var info_panel: Panel = $LobbyUI/InfoPanel
@onready var info_title: Label = $LobbyUI/InfoPanel/Title
@onready var info_body: Label = $LobbyUI/InfoPanel/Body
@onready var upgrade_panel: Panel = $LobbyUI/UpgradePanel
@onready var coin_label: Label = $LobbyUI/UpgradePanel/CoinLabel
@onready var upgrade_buttons := {
	"max_life": $LobbyUI/UpgradePanel/VBox/MaxLifeButton,
	"speed": $LobbyUI/UpgradePanel/VBox/SpeedButton,
	"jump": $LobbyUI/UpgradePanel/VBox/JumpButton,
	"sword": $LobbyUI/UpgradePanel/VBox/SwordButton,
}


func _ready() -> void:
	# Keep this track owned by the lobby so it stops when leaving the scene.
	ProjectMusicController.stop()
	$LobbyMusic.play()
	bestiary_catalog = preload("res://Scenes/Interactables/bestiary_catalog.tscn").instantiate()
	$LobbyUI.add_child(bestiary_catalog)
	$LobbyUI.visible = true
	$LobbyUI.show()
	player_data.restore_life()
	prompt_panel.hide()
	info_panel.hide()
	upgrade_panel.hide()

	$LobbyUI/InfoPanel/CloseButton.pressed.connect(close_panels)
	$LobbyUI/UpgradePanel/CloseButton.pressed.connect(close_panels)

	for upgrade_id in upgrade_buttons.keys():
		upgrade_buttons[upgrade_id].pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))

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
	upgrade_panel.show()


func open_bestiary_panel() -> void:
	close_panels()
	bestiary_catalog.open_book()


func open_artifact_panel() -> void:
	close_panels()
	bestiary_catalog.open_book(true)


func travel_to_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		scene_path = LEVEL_1_SCENE

	call_deferred("_change_to_scene", scene_path)


func _change_to_scene(scene_path: String) -> void:
	if not is_inside_tree():
		return

	if has_node("/root/SceneLoader"):
		get_node("/root/SceneLoader").call("load_scene", scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)


func close_panels() -> void:
	if is_instance_valid(bestiary_catalog):
		bestiary_catalog.close_book()
	info_panel.hide()
	upgrade_panel.hide()


func refresh_upgrade_panel() -> void:
	coin_label.text = "Coin: " + str(player_data.coin)

	for upgrade_id in upgrade_buttons.keys():
		var button: Button = upgrade_buttons[upgrade_id]
		button.tooltip_text = player_data.UPGRADE_DATA[upgrade_id]["description"]
		var level: int = player_data.upgrade_levels[upgrade_id]
		var max_level: int = player_data.UPGRADE_DATA[upgrade_id]["max_level"]

		if level >= max_level:
			button.text = "%s Lv.%d/%d - MAX" % [player_data.get_upgrade_name(upgrade_id), level, max_level]
			button.disabled = true
		else:
			var cost := player_data.get_upgrade_cost(upgrade_id)
			button.text = "%s Lv.%d/%d - %d coin" % [player_data.get_upgrade_name(upgrade_id), level, max_level, cost]
			button.disabled = player_data.coin < cost


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
