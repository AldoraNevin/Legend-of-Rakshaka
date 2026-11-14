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

@export var attack_distance: float = 75.0
@export var attack_height: float = 55.0
@export var attack_cooldown: float = 0.8
@export var damage: int = 12
@export var max_health: int = 3
@export var gravity: float = 1000.0

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
var hit_targets: Array[Node2D] = []


func _ready() -> void:
	health = max_health
	home_x = global_position.x
	hitbox_x = abs(hitbox.position.x)
	probe_x = abs(floor_check.position.x)

	player = get_tree().get_first_node_in_group("player") as Node2D
	anim.animation_finished.connect(_on_animation_finished)

	face(1.0)
	play_clip(&"Idle")


func _physics_process(delta: float) -> void:
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
			damage_overlapping_player()

	move_and_slide()


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

	if absf(offset.x) <= attack_distance \
			and absf(offset.y) <= attack_height:
		if cooldown_left <= 0.0 and is_on_floor():
			state = State.WINDUP
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
	floor_check.position.x = probe_x * facing


func has_floor_ahead() -> bool:
	floor_check.force_raycast_update()
	return floor_check.is_colliding()


func damage_overlapping_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body in hit_targets:
			continue
		if body.has_method("take_damage"):
			hit_targets.append(body)
			body.take_damage(damage)


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return

	health -= amount
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
				play_clip(&"AttackActive")

		&"AttackActive":
			if state == State.ACTIVE:
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
				player_data.discover_enemy("Aul")
				queue_free()
