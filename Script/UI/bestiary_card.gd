extends Button
## Layout and styles live in bestiary_card.tscn; this only updates entry content.

func configure(entry: Dictionary, portrait: Texture2D, show_identity: bool = false) -> void:
	var unlocked: bool = entry.get("is_unlocked", false) or show_identity
	$Portrait.texture = portrait
	$NameLabel.text = str(entry.get("name", "")).to_upper() if unlocked else "???"
	tooltip_text = str(entry.get("name", "")) if unlocked else "Belum ditemukan"
	accessibility_name = tooltip_text
