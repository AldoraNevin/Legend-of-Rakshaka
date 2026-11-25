extends CanvasLayer

const HEALTH_HUD := preload("res://Scenes/UI/health_hud.tscn")
var health_hud: Control
var frame_art: AtlasTexture
var fill_art: AtlasTexture
var displayed_trail := 0.0
var previous_capacity := -1
var previous_hp := -1
var trail_tween: Tween

func _ready() -> void:
	# Keep existing level scenes compatible while replacing the heart counter.
	$heart.hide()
	health_hud = HEALTH_HUD.instantiate()
	add_child(health_hud)
	frame_art = health_hud.get_node("Frame").texture
	fill_art = health_hud.get_node("HealthBar").texture_progress
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
	if hp == previous_hp and previous_capacity == player_data.max_life:
		return
	var trail: TextureProgressBar = health_hud.get_node("DamageTrail")
	if trail_tween:
		trail_tween.kill()
	if previous_capacity != player_data.max_life:
		previous_capacity = player_data.max_life
		var extra := roundi(maxi(0, previous_capacity - player_data.MAX_HEALTH) * 2.88)
		var frame: TextureRect = health_hud.get_node("Frame")
		frame.size.x = 300 + extra
		bar.size.x = 288 + extra
		trail.size.x = bar.size.x
		frame.texture = _extend_hud_strip(frame_art, 300, extra) if extra else frame_art
		bar.texture_progress = _extend_hud_strip(fill_art, 288, extra) if extra else fill_art
		trail.texture_progress = bar.texture_progress
	bar.max_value = previous_capacity
	trail.max_value = bar.max_value
	bar.value = hp
	if hp < previous_hp:
		_set_trail(maxf(displayed_trail, previous_hp))
		trail_tween = create_tween()
		trail_tween.tween_interval(0.30)
		trail_tween.tween_method(_set_trail, displayed_trail, float(hp), 0.65).set_trans(Tween.TRANS_SINE)
	else:
		_set_trail(hp)
	previous_hp = hp

func _set_trail(hp: float) -> void:
	displayed_trail = hp
	health_hud.get_node("DamageTrail").value = hp

# Copy at atlas resolution to retain the original rim, bevel and angled tip.
func _extend_hud_strip(art: AtlasTexture, base_width: int, extra: int) -> Texture2D:
	var source := art.get_image()
	var width := source.get_width()
	var height := source.get_height()
	var added := roundi(float(extra * width) / base_width)
	var join := roundi(width * 0.64)
	var sample_width := 32
	var result := Image.create_empty(width + added, height, false, source.get_format())
	result.blit_rect(source, Rect2i(0, 0, join, height), Vector2i.ZERO)
	for offset in range(0, added, sample_width):
		var count := mini(sample_width, added - offset)
		result.blit_rect(source, Rect2i(join - sample_width, 0, count, height), Vector2i(join + offset, 0))
	result.blit_rect(source, Rect2i(join, 0, width - join, height), Vector2i(join + added, 0))
	return ImageTexture.create_from_image(result)
