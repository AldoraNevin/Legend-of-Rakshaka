extends SceneTree
const CATALOG = preload("res://Script/Stage/Modular/enemy_catalog.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var player := CharacterBody2D.new()
	player.collision_layer = 1
	player.collision_mask = 0
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(13, 38)
	collider.shape = rectangle
	player.add_child(collider)
	player.add_to_group("player")
	root.add_child(player)
	for species in CATALOG.SPECIES:
		var enemy := CATALOG.create(species)
		var authored: Node2D = load("res://Scenes/Enemies/%s.tscn" % species).instantiate()
		for path in ["CollisionShape2D", "Hitbox/CollisionShape2D", "Hurtbox/CollisionShape2D"]:
			assert(enemy.get_node(path).transform == authored.get_node(path).transform)
			assert(enemy.get_node(path).shape == authored.get_node(path).shape)
		var original: AnimatedSprite2D = authored.get_node("AnimatedSprite2D")
		assert(enemy.get_node("AnimatedSprite2D").transform == original.transform)
		var idle_texture: Texture2D = original.sprite_frames.get_frame_texture(&"Idle", 0)
		var idle_bottom: float = idle_texture.get_image().get_used_rect().end.y
		var expected_foot: float = original.position.y + (idle_bottom - idle_texture.get_height() * 0.5 + original.offset.y) * original.scale.y
		authored.free()
		root.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.anim.stop()
		for clip in enemy.sprite.sprite_frames.get_animation_names():
			for index in range(enemy.sprite.sprite_frames.get_frame_count(clip)):
				enemy.sprite.animation = clip
				enemy.sprite.frame = index
				enemy.sprite.align_feet()
				var bounds: Rect2 = enemy.sprite.visible_bounds(clip, index)
				var texture: Texture2D = enemy.sprite.sprite_frames.get_frame_texture(clip, index)
				var foot: float = enemy.sprite.position.y + (bounds.end.y - texture.get_height() * 0.5 + enemy.sprite.offset.y) * enemy.sprite.scale.y
				assert(is_equal_approx(foot, expected_foot), "%s %s frame %d: %f" % [species, clip, index, foot])
		for direction in [-1, 1]:
			enemy.face(direction)
			player.position = Vector2(direction * 200, -22)
			await physics_frame
			await physics_frame
			assert(not enemy.can_reach_player(), species + " attacks too early")
			player.position = enemy.get_node("Hitbox/CollisionShape2D").global_position
			await physics_frame
			await physics_frame
			assert(enemy.can_reach_player(), species + " cannot reach close player")
			player.position.y = -300
			await physics_frame
			await physics_frame
			assert(not enemy.can_reach_player(), species + " attacks wrong floor")
		enemy.free()
	player.free()
	print("PASS: all species/all frames preserve authored collision and Idle anchors; attack reach matches scaled hitboxes on both sides and rejects distant/raised targets.")
	quit()

