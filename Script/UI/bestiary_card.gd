@tool
extends Button
## NameLabel.text and Portrait.texture are the authored identity of this entry.
@export var boss_border := false
@export var entity_id := ""
@export var region := "Nusantara"
@export var category := ""
@export_multiline var description := ""
@export_multiline var history := ""
@export_multiline var attack_pattern := ""
@export_multiline var tactics := ""
@export var hp := 0
@export var attack := 0

func get_entry() -> Dictionary:
	return {"entity_id": entity_id, "name": $NameLabel.text, "portrait": $Portrait.texture,
		"region": region, "category": category, "description": description,
		"history": history, "attack_pattern": attack_pattern, "tactics": tactics,
		"hp": hp, "attack": attack, "is_unlocked": true}

func configure(entry: Dictionary, portrait: Texture2D, show_identity: bool = false) -> void:
	var unlocked: bool = entry.get("is_unlocked", false) or show_identity
	$Portrait.texture = portrait
	$NameLabel.text = str(entry.get("name", "")) if unlocked else "???"
	tooltip_text = str(entry.get("name", "")) if unlocked else "Belum ditemukan"
	accessibility_name = tooltip_text


func _ready() -> void:
	if not boss_border:
		return
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var frame := StyleBoxFlat.new()
		frame.draw_center = state != "focus"
		frame.bg_color = Color("#ffad48") if state == "normal" else Color("#ffbd63")
		frame.border_color = Color("#934312") if state == "normal" else Color("#b44c08")
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(4)
		add_theme_stylebox_override(state, frame)
	$NameLabel.add_theme_color_override("font_color", Color("#422007"))
