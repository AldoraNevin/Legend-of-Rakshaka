extends SceneTree
const CATALOG = preload("res://Script/Stage/Modular/enemy_catalog.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2000, 20)
	floor_shape.shape = rectangle
	floor_body.position.y = 100
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	var player := CharacterBody2D.new()
	player.collision_layer = 1
	player.collision_mask = 0
	var player_shape := CollisionShape2D.new()
	var player_rect := RectangleShape2D.new()
	player_rect.size = Vector2(13, 38)
	player_shape.shape = player_rect
	player.add_child(player_shape)
	player.add_to_group("player")
	player.position = Vector2(800, 0)
	root.add_child(player)
	for species in CATALOG.SPECIES:
		for direction in [-1.0, 1.0]:
			var enemy := CATALOG.create(species)
			root.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.anim.active = false
			enemy.state = enemy.State.RECOVERY
			for step in range(35):
				await physics_frame
				enemy._physics_process(1.0 / 60.0)
			assert(enemy.is_on_floor(), species)
			enemy.face(direction)
			var attack_shape: CollisionShape2D = enemy.get_node("Hitbox/CollisionShape2D")
			var bounds: Rect2 = attack_shape.global_transform * attack_shape.shape.get_rect()
			var edge := bounds.end.x if direction > 0 else bounds.position.x
			player.position = Vector2(edge + direction * 20, bounds.get_center().y)
			await physics_frame
			await physics_frame
			assert(not enemy.can_reach_player(), species + " test needs a gap")
			if species in ["Bajang", "MahesaSura", "WarakNgendhog"]:
				assert(enemy.can_start_attack(), species + " should charge before contact")
				enemy.state = enemy.State.CHASE
				enemy.chase()
				assert(enemy.state == enemy.State.WINDUP)
			else:
				assert(not enemy.can_start_attack(), species + " must stay melee")
			player.position.x += direction * 200
			await physics_frame
			await physics_frame
			assert(not enemy.can_start_attack(), species + " must reject unreachable targets")
			enemy.attack_direction = direction
			enemy.state = enemy.State.WINDUP
			var origin: Vector2 = enemy.position
			enemy._on_animation_finished(&"AttackWindUp")
			if species == "Bajang":
				assert(enemy.velocity.y < 0)
			for step in range(18):
				await physics_frame
				enemy._physics_process(1.0 / 60.0)
			var distance: float = (enemy.position.x - origin.x) * direction
			if species in ["Bajang", "MahesaSura", "WarakNgendhog"]:
				assert(distance > 25 and distance < 55, "%s moved %f" % [species, distance])
			else:
				assert(is_zero_approx(distance), species)
			enemy._on_animation_finished(&"AttackActive")
			assert(enemy.lunge_time_left == 0 and enemy.velocity.x == 0)
			enemy.lunge_time_left = 1
			enemy.take_damage(1)
			assert(enemy.lunge_time_left == 0)
			enemy.free()
	floor_body.free()
	player.free()
	print("PASS: only three species lunge in both directions, Bajang hops, distance is bounded, recovery and damage stop the lunge.")
	quit()
