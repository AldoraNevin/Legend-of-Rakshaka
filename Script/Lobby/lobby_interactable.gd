extends Area2D

@export_enum("upgrade", "npc", "bestiary", "artifact", "travel") var interaction_type := "npc"
@export var title := "Interact"
@export_multiline var description := ""
@export var target_scene := ""
@export var auto_activate_on_enter := false

var player_inside := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func activate(lobby: Node) -> void:
	match interaction_type:
		"upgrade":
			lobby.open_upgrade_panel()
		"bestiary":
			lobby.open_bestiary_panel()
		"artifact":
			lobby.open_artifact_panel()
		"travel":
			lobby.travel_to_scene(target_scene)
		_:
			lobby.open_message_panel(title, description)


func _get_lobby() -> Node:
	if owner != null and owner.has_method("set_current_interactable"):
		return owner
	var tree := get_tree()
	if tree != null and tree.current_scene != null and tree.current_scene.has_method("set_current_interactable"):
		return tree.current_scene
	var p := get_parent()
	while p != null:
		if p.has_method("set_current_interactable"):
			return p
		p = p.get_parent()
	return null


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_inside = true
	var lobby := _get_lobby()
	if lobby != null:
		lobby.set_current_interactable(self)
		if auto_activate_on_enter:
			call_deferred("activate", lobby)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_inside = false
	var lobby := _get_lobby()
	if lobby != null:
		lobby.clear_current_interactable(self)
