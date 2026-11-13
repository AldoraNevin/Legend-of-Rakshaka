@tool
extends Button
## NameLabel.text and Portrait.texture are the authored identity of this entry.
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
