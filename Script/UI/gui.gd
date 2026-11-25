extends CanvasLayer

const HEALTH_HUD := preload("res://Scenes/UI/health_hud.tscn")
var health_hud: Control
var previous_hp := -1
var trail_tween: Tween

func _ready() -> void:
	# Keep existing level scenes compatible while replacing the heart counter.
	$heart.hide()
	health_hud = HEALTH_HUD.instantiate()
	add_child(health_hud)
	add_child(preload("res://Script/UI/healing_skill_hud.gd").new())
	var sukma := preload("res://Legend of Rakshaka/UI HUD/Sukma.png")
	$coin_sprite.texture = sukma
	$coin_sprite.hframes = 1
	$coin_sprite.vframes = 1
	$coin_sprite.frame = 0
	$coin_sprite.region_enabled = false
	$coin_sprite.scale = Vector2.ONE * (32.0 / maxf(sukma.get_width(), sukma.get_height()))
	$coin_sprite.position = Vector2(40, 138)
	$coin_number.position = Vector2(59, 118)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	$coin_number.text = str(player_data.coin)
	var hp := clampi(player_data.life, 0, player_data.max_life)
	var bar: TextureProgressBar = health_hud.get_node("HealthBar")
	if hp == previous_hp and bar.max_value == player_data.max_life:
		return
	var trail: TextureProgressBar = health_hud.get_node("DamageTrail")
	if trail_tween:
		trail_tween.kill()
	bar.max_value = player_data.max_life
	trail.max_value = bar.max_value
	bar.value = hp
	if hp < previous_hp:
		trail.value = maxf(trail.value, previous_hp)
		trail_tween = create_tween()
		trail_tween.tween_interval(0.30)
		trail_tween.tween_property(trail, "value", float(hp), 0.65).set_trans(Tween.TRANS_SINE)
	else:
		trail.value = hp
	previous_hp = hp
