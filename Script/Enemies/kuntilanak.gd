extends CharacterBody2D

@export var patrol_speed := 25.0
@export var chase_speed := 55.0
@export var patrol_distance := 80.0
@export var attack_distance := 28.0
@export var attack_height := 42.0
@export var first_attack_delay := 0.5
@export var attack_cooldown := 0.8
@export var contact_damage := 1
@export var max_health := 3
@export var gravity := 1000.0
@export var edge_probe_forward := 24.0
@export var edge_probe_down := 180.0
@export var edge_max_drop := 12.0

var direction := -1.0
var health := 0
var is_dead := false
var is_attacking := false
var can_attack := true
var has_attacked_player := false
var spawn_position := Vector2.ZERO
var player: Node2D = null
var is_chasing := false
var player_in_detection := false
var sprite_base_scale_x := 1.0
var damage_area_base_x := 0.0
var hurtbox_base_x := 0.0
var current_floor_y := INF

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_area: Area2D = $DamageArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")


func _ready() -> void:
	health = max_health
	spawn_position = global_position
	sprite_base_scale_x = abs(sprite.scale.x)
	damage_area_base_x = abs(damage_area.position.x)
	hurtbox_base_x = abs(hurtbox.position.x)
	player = get_tree().get_first_node_in_group("player") as Node2D
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.add_to_group("enemy_hurtbox")

	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	play_animation("Idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_attacking:
		apply_gravity(delta)
		move_and_slide()
		return

	find_player()
	update_state()
	apply_gravity(delta)
	update_current_floor_y()

	if can_attack_player():
		start_attack()
		return

	if is_chasing:
		chase_player(delta)
	else:
		patrol()

	move_and_slide()

	update_current_floor_y()
	if is_on_wall() or should_turn_at_edge():
		turn_around()
		velocity.x = 0


func find_player() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D


func update_state() -> void:
	if player == null:
		is_chasing = false
		return

	if detection_area != null:
		is_chasing = player_in_detection
	else:
		is_chasing = abs(player.global_position.x - global_position.x) <= patrol_distance


func patrol() -> void:
	if abs(global_position.x - spawn_position.x) >= patrol_distance:
		direction = -sign(global_position.x - spawn_position.x)
		if direction == 0:
			direction = -1

	if not can_walk_toward(direction):
		turn_around()
		velocity.x = 0
		play_animation("Idle")
		return

	velocity.x = direction * patrol_speed
	update_facing()

	play_animation("Idle")


func chase_player(delta: float) -> void:
	if player == null:
		return

	var x_direction: float = sign(player.global_position.x - global_position.x)

	if x_direction != 0 and can_walk_toward(x_direction):
		direction = x_direction
		update_facing()

	if should_turn_at_edge():
		velocity.x = 0
	else:
		velocity.x = move_toward(velocity.x, direction * chase_speed, chase_speed * 4.0 * delta)

	play_animation("Chase")


func turn_around() -> void:
	direction *= -1
	update_facing()


func update_facing() -> void:
	# Kuntilanak sprite source faces left, so positive direction needs a horizontal flip.
	sprite.scale.x = -direction * sprite_base_scale_x
	damage_area.position.x = direction * damage_area_base_x
	hurtbox.position.x = direction * hurtbox_base_x


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


func should_turn_at_edge() -> bool:
	return not can_walk_toward(direction)


func can_walk_toward(x_direction: float) -> bool:
	if not is_on_floor():
		return false

	if x_direction == 0:
		return true

	var next_floor_y: float = get_floor_y_at(global_position.x + sign(x_direction) * edge_probe_forward)
	if is_inf(next_floor_y) or is_inf(current_floor_y):
		return false

	return abs(next_floor_y - current_floor_y) <= edge_max_drop


func update_current_floor_y() -> void:
	if not is_on_floor():
		return

	var floor_y: float = get_floor_y_at(global_position.x)
	if not is_inf(floor_y):
		current_floor_y = floor_y


func get_floor_y_at(world_x: float) -> float:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var start: Vector2 = Vector2(world_x, global_position.y - 8.0)
	var end: Vector2 = start + Vector2(0.0, edge_probe_down)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, end, 2, [self])
	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		return INF

	var point: Vector2 = result["position"]
	return point.y


func face_player() -> void:
	if player == null:
		return

	var x_direction: float = sign(player.global_position.x - global_position.x)
	if x_direction != 0:
		direction = x_direction
		update_facing()


func can_attack_player() -> bool:
	if player == null or not player_in_detection or not can_attack:
		return false

	var distance_to_player: Vector2 = player.global_position - global_position
	return abs(distance_to_player.x) <= attack_distance and abs(distance_to_player.y) <= attack_height


func start_attack() -> void:
	if is_dead or is_attacking or not can_attack:
		return

	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	face_player()

	if not has_attacked_player:
		play_animation("Idle")
		await get_tree().create_timer(first_attack_delay).timeout

		if is_dead or not can_attack_player_ignore_cooldown():
			is_attacking = false
			can_attack = true
			return

	has_attacked_player = true
	play_animation("Attack")

	await get_tree().create_timer(0.25).timeout

	if not is_dead and player != null and can_attack_player_ignore_cooldown():
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)

	await get_tree().create_timer(0.35).timeout

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func can_attack_player_ignore_cooldown() -> bool:
	if player == null or not player_in_detection:
		return false

	var distance_to_player: Vector2 = player.global_position - global_position
	return abs(distance_to_player.x) <= attack_distance and abs(distance_to_player.y) <= attack_height


func play_animation(animation_name: String) -> void:
	if anim.has_animation(animation_name) and anim.current_animation != animation_name:
		anim.play(animation_name)


func _on_damage_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		player = body as Node2D
		start_attack()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.is_in_group("player_sword"):
		pass


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body as Node2D
		player_in_detection = true


func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		player_in_detection = false
		has_attacked_player = false


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()
	else:
		if anim.has_animation("Hit"):
			anim.play("Hit")
			await anim.animation_finished

		if not is_dead and anim.has_animation("Idle"):
			anim.play("Idle")


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_data.discover_enemy("Kuntilanak")

	damage_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)

	if anim.has_animation("Dead"):
		anim.play("Dead")
		await anim.animation_finished

	queue_free()
