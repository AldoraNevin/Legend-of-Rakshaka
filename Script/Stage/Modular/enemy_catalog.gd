extends RefCounted
## Only these species participate in modular encounters.
const SPECIES := ["Aul", "Bajang", "Cindaku", "Genderuwo", "Gupala",
	"MahesaSura", "Sarpaneka", "WarakNgendhog"]
const BEHAVIOR = preload("res://Script/Enemies/aul.gd")
const VISUAL = preload("res://Script/Enemies/enemy_visual.gd")

static func create(species: String) -> CharacterBody2D:
	assert(species in SPECIES)
	# Instantiate the authored body, sprite, hurtbox and hitbox together.
	var enemy: CharacterBody2D = load("res://Scenes/Enemies/%s.tscn" % species).instantiate()
	if enemy.get_script() == null:
		enemy.set_script(BEHAVIOR)
	enemy.enemy_name = species
	match species:
		"Bajang":
			enemy.attack_lunge_speed = 180.0
			enemy.attack_hop_speed = 100.0
		"MahesaSura":
			enemy.attack_lunge_speed = 220.0
		"WarakNgendhog":
			enemy.attack_lunge_speed = 200.0
	if species == "MahesaSura":
		enemy.enemy_name = "Mahesa Sura"
	elif species == "WarakNgendhog":
		enemy.enemy_name = "Warak Ngendhog"
	# Uniform stage scale preserves all authored sprite/collider proportions.
	enemy.scale *= 0.5
	enemy.collision_layer = 64
	enemy.collision_mask = 2
	var hurtbox: Area2D = enemy.get_node("Hurtbox")
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	var hitbox: Area2D = enemy.get_node("Hitbox")
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1
	var floor_check := enemy.get_node_or_null("FloorCheck") as RayCast2D
	if floor_check == null:
		floor_check = enemy.get_node("RayCast2D")
		floor_check.name = "FloorCheck"
		var body: CollisionShape2D = enemy.get_node("CollisionShape2D")
		var bounds: Rect2 = body.transform * body.shape.get_rect()
		floor_check.position = Vector2(maxf(absf(bounds.position.x), absf(bounds.end.x)) + 5, bounds.end.y - 10)
		floor_check.target_position = Vector2(0, 20)
	floor_check.enabled = true
	floor_check.collision_mask = 2
	var visual: AnimatedSprite2D = enemy.get_node("AnimatedSprite2D")
	# AnimationPlayer owns frame timing; disable the scene's sprite autoplay.
	visual.autoplay = ""
	visual.stop()
	visual.set_script(VISUAL)
	visual.capture_authored_baseline()
	var animation: AnimationPlayer = enemy.get_node("AnimationPlayer")
	var library: AnimationLibrary = animation.get_animation_library(&"").duplicate(true)
	animation.remove_animation_library(&"")
	if species == "Cindaku":
		var total := visual.sprite_frames.get_frame_count(&"Attack")
		var split := maxi(1, total / 3)
		library.add_animation(&"AttackWindUp", attack_phase(visual.sprite_frames, 0, split))
		library.add_animation(&"AttackActive", attack_phase(visual.sprite_frames, split, split * 2))
		library.add_animation(&"AttackRecovery", attack_phase(visual.sprite_frames, split * 2, total))
	for clip in [&"AttackWindUp", &"AttackActive", &"AttackRecovery", &"Hit", &"Dead"]:
		library.get_animation(clip).loop_mode = Animation.LOOP_NONE
	animation.add_animation_library(&"", library)
	return enemy

static func attack_phase(frames: SpriteFrames, start: int, end: int) -> Animation:
	var clip := Animation.new()
	var step := 1.0 / frames.get_animation_speed(&"Attack")
	clip.length = (end - start) * step
	var strip := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(strip, NodePath("AnimatedSprite2D:animation"))
	clip.value_track_set_update_mode(strip, Animation.UPDATE_DISCRETE)
	clip.track_insert_key(strip, 0, &"Attack")
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("AnimatedSprite2D:frame"))
	clip.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	for index in range(start, end):
		clip.track_insert_key(track, (index - start) * step, index)
	return clip
