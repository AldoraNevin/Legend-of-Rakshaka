extends CanvasLayer

const HEALTH_HUD := preload("res://Scenes/UI/health_hud.tscn")
var health_hud: Control

func _ready() -> void:
	# Keep existing level scenes compatible while replacing the heart counter.
	$heart.hide()
	health_hud = HEALTH_HUD.instantiate()
	add_child(health_hud)
	$coin_sprite.position = Vector2(27, 86)
	$coin_number.position = Vector2(55, 63)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	$coin_number.text = str(player_data.coin)
	var hp := clampi(player_data.life, 0, player_data.MAX_HEALTH)
	health_hud.get_node("HealthBar").value = hp
	health_hud.get_node("HealthText").text = "HP %d / %d" % [hp, player_data.MAX_HEALTH]
