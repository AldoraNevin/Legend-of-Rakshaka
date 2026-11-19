extends CharacterBody2D

enum State {
	PATROL,
	CHASE,
	WINDUP,
	ACTIVE,
	RECOVERY,
	HIT,
	DEAD
}

@export var patrol_speed: float = 25.0
@export var chase_speed: float = 65.0
@export var patrol_distance: float = 120.0

@export var detect_distance: float = 220.0
@export var lose_distance: float = 340.0
@export var detect_height: float = 80.0

@export var attack_cooldown: float = 0.8
@export var damage: int = 12
@export var max_health: int = 3
@export var gravity: float = 1000.0
@export var enemy_name := "Aul"
@export_group("Attack movement")
@export var attack_lunge_speed := 0.0
@export var attack_lunge_duration := 0.22
@export var attack_hop_speed := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var floor_check: RayCast2D = $FloorCheck

var state: State = State.PATROL
var player: Node2D
var health: int
var facing: float = 1.0
var home_x: float
var cooldown_left: float = 0.0
var hitbox_x: float
var probe_x: float
var hit_shape_x: float
var hit_targets: Array[Node2D] = []
var lunge_time_left := 0.0
var attack_direction := 1.0


func _ready() -> void:
	add_to_group("artifact_enemies")
	health = max_health
	home_x = global_position.x
	hitbox_x = hitbox.position.x
	hit_shape_x = $Hitbox/CollisionShape2D.position.x
	probe_x = abs(floor_check.position.x)

	player = get_tree().get_first_node_in_group("player") as Node2D
	anim.animation_finished.connect(_on_animation_finished)

	face(1.0)
	play_clip(&"Idle")


func _physics_process(delta: float) -> void:
	if preload("res://Script/Enemies/artifact_status.gd").tick(self, delta):
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = 0.0

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	match state:
		State.PATROL, State.CHASE:
			update_detection()

			if state == State.CHASE:
				chase()
			else:
				patrol()

		State.ACTIVE:
			if lunge_time_left > 0.0:
				if is_on_floor() and not has_floor_ahead():
					lunge_time_left = 0.0
				else:
					velocity.x = attack_direction * attack_lunge_speed * minf(1.0, lunge_time_left / delta)
					lunge_time_left = maxf(0.0, lunge_time_left - delta)
			damage_overlapping_player()

	move_and_slide()
	if state == State.ACTIVE and is_on_wall():
		lunge_time_left = 0.0


func update_detection() -> void:
	if not is_instance_valid(player):
		state = State.PATROL
		return

	var offset: Vector2 = player.global_position - global_position

	if state == State.PATROL:
		if absf(offset.x) <= detect_distance \
				and absf(offset.y) <= detect_height:
			state = State.CHASE
	else:
		if absf(offset.x) > lose_distance \
				or absf(offset.y) > detect_height:
			state = State.PATROL


func patrol() -> void:
	# Patrol di antara home_x - distance dan home_x + distance.
	if global_position.x >= home_x + patrol_distance:
		face(-1.0)
	elif global_position.x <= home_x - patrol_distance:
		face(1.0)

	if is_on_floor() and (is_on_wall() or not has_floor_ahead()):
		face(-facing)

	if is_on_floor() and has_floor_ahead():
		velocity.x = facing * patrol_speed

	play_clip(&"Idle")


func chase() -> void:
	if not is_instance_valid(player):
		return

	var offset: Vector2 = player.global_position - global_position
	face(offset.x)

	if can_start_attack():
		if cooldown_left <= 0.0 and is_on_floor():
			state = State.WINDUP
			attack_direction = facing
			play_clip(&"AttackWindUp")
		else:
			play_clip(&"Idle")
		return

	if is_on_floor() and has_floor_ahead():
		velocity.x = facing * chase_speed

	play_clip(&"Chase")


func face(value: float) -> void:
	if is_zero_approx(value):
		return

	facing = signf(value)

	# Gambar Aul aslinya menghadap kanan.
	sprite.flip_h = facing < 0.0
	hitbox.position.x = hitbox_x * facing
	$Hitbox/CollisionShape2D.position.x = hit_shape_x * facing
	floor_check.position.x = probe_x * facing


func has_floor_ahead() -> bool:
	floor_check.force_raycast_update()
	return floor_check.is_colliding()


func lunge_start_reach() -> float:
	# Leave travel in reserve so the active hitbox reaches the target before recovery.
	var active_duration := anim.get_animation(&"AttackActive").length / maxf(absf(anim.speed_scale), 0.01)
	return attack_lunge_speed * minf(attack_lunge_duration, active_duration) * 0.8


func can_start_attack() -> bool:
	if can_reach_player():
		return true
	if attack_lunge_speed <= 0.0 or not is_on_floor() or not has_floor_ahead():
		return false
	var reach := lunge_start_reach()
	var shape: CollisionShape2D = $Hitbox/CollisionShape2D
	var obstacle := PhysicsRayQueryParameters2D.create(shape.global_position,
		shape.global_position + Vector2(facing * reach, 0), 2, [get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(obstacle).is_empty():
		return false
	# Test the same hitbox along the charge path, without extending damage range.
	for step in range(1, 5):
		if can_reach_player(Vector2(facing * reach * step / 4.0, 0)):
			return true
	return false


func can_reach_player(projected_offset := Vector2.ZERO) -> bool:
	# Query the actual scaled attack shape after facing the target. A fixed
	# world-space distance started attacks outside the half-size rig's reach.
	var shape: CollisionShape2D = $Hitbox/CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += projected_offset
	query.collision_mask = hitbox.collision_mask
	query.exclude = [get_rid()]
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider == player:
			return true
	return false


func damage_overlapping_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body in hit_targets:
			continue
		if body.has_method("take_damage"):
			hit_targets.append(body)
			body.take_damage(damage, self)


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return

	health -= amount
	lunge_time_left = 0.0
	velocity.x = 0.0
	hit_targets.clear()

	if health <= 0:
		state = State.DEAD
		hurtbox.set_deferred("monitorable", false)
		play_clip(&"Dead")
	else:
		state = State.HIT
		# Mulai ulang reaksi jika terkena pukulan berikutnya.
		anim.stop()
		anim.play(&"Hit")


func play_clip(clip: StringName) -> void:
	if anim.current_animation != clip:
		anim.play(clip)


func _on_animation_finished(clip: StringName) -> void:
	match clip:
		&"AttackWindUp":
			if state == State.WINDUP:
				state = State.ACTIVE
				hit_targets.clear()
				lunge_time_left = 0.0
				if attack_lunge_speed > 0.0 and is_on_floor() and has_floor_ahead():
					lunge_time_left = attack_lunge_duration
					velocity.y = -attack_hop_speed
				play_clip(&"AttackActive")

		&"AttackActive":
			if state == State.ACTIVE:
				lunge_time_left = 0.0
				velocity.x = 0.0
				state = State.RECOVERY
				play_clip(&"AttackRecovery")

		&"AttackRecovery":
			if state == State.RECOVERY:
				cooldown_left = attack_cooldown
				state = State.PATROL

		&"Hit":
			if state == State.HIT:
				cooldown_left = attack_cooldown
				state = State.PATROL

		&"Dead":
			if state == State.DEAD:
				player_data.enemy_resource_reward()
				player_data.discover_enemy(enemy_name)
				queue_free()
