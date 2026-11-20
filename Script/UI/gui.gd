extends CanvasLayer

const HEALTH_HUD := preload("res://Scenes/UI/health_hud.tscn")
var health_hud: Control

func _ready() -> void:
	# Keep existing level scenes compatible while replacing the heart counter.
	$heart.hide()
	health_hud = HEALTH_HUD.instantiate()
	add_child(health_hud)
	add_child(preload("res://Script/UI/healing_skill_hud.gd").new())
	var sukma := preload("res://Assets/Legend of Rakshaka/UI HUD/Sukma.png")
	$coin_sprite.texture = sukma
	$coin_sprite.hframes = 1
	$coin_sprite.vframes = 1
	$coin_sprite.frame = 0
	$coin_sprite.region_enabled = false
	$coin_sprite.scale = Vector2.ONE * (32.0 / maxf(sukma.get_width(), sukma.get_height()))
	$coin_sprite.position = Vector2(112, 90)
	$coin_number.position = Vector2(136, 72)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	$coin_number.text = str(player_data.coin)
	var hp := clampi(player_data.life, 0, player_data.max_life)
	health_hud.get_node("HealthBar").max_value = player_data.max_life
	health_hud.get_node("HealthBar").value = hp
	health_hud.get_node("HealthText").text = "HP %d / %d" % [hp, player_data.max_life]
