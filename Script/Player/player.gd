extends CharacterBody2D

enum PlayerStates { MOVE, SWORD, DEAD, DASH, HIT }

const ENEMY_BODY_LAYER := 5

var input := 0.0
var facing := 1
var is_attacking := false
var is_dead := false
var is_wall_sliding := false
var is_invincible := false
var can_dash := true

var jump_count := 0
var wall_jump_count := 0
var sword_hit_targets: Array[Node] = []

var current_state := PlayerStates.MOVE

@export var speed := 100.0
@export var gravity := 1000.0

@export var max_jump := 2
@export var jump_force := 300.0

@export var max_wall_jump := 2
@export var wall_slide_speed := 80.0
@export var wall_jump_force := 350.0
@export var wall_jump_push := 800.0
@export var wall_jump_short_push := 180.0

@export var dash_speed := 600.0
@export var dash_time := 0.12
@export var dash_cooldown := 0.35
@export var sword_damage := 1

@onready var wall: RayCast2D = $wall_ray
@onready var anim: AnimationPlayer = $anim
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_area: Area2D = $sword
@onready var sword_collider: CollisionShape2D = $sword/Sword_Collider


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	add_to_group("player")
	player_data.apply_player_stats(self)
	sword_area.add_to_group("player_sword")
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(ENEMY_BODY_LAYER, true)
	sword_collider.disabled = true


func _physics_process(delta: float) -> void:
	if player_data.life <= 0 and not is_dead:
		start_dead()

	match current_state:
		PlayerStates.MOVE:
			movement(delta)
		PlayerStates.SWORD:
			sword(delta)
		PlayerStates.HIT:
			dead(delta)
		PlayerStates.DEAD:
			dead(delta)
		PlayerStates.DASH:
			move_and_slide()


func movement(delta: float) -> void:
	input_movement(delta)

	if Input.is_action_just_pressed("ui_sword"):
		start_sword_attack()
		return

	if Input.is_action_just_pressed("ui_dash") and can_dash:
		start_dash()
		return

	move_and_slide()
	update_animation()


func sword(delta: float) -> void:
	input_movement(delta)
	check_sword_hits()
	move_and_slide()


func dead(delta: float) -> void:
	velocity.x = 0
	apply_gravity(delta)
	move_and_slide()


func start_dead() -> void:
	is_dead = true
	is_attacking = false
	is_invincible = false
	current_state = PlayerStates.DEAD
	sword_collider.set_deferred("disabled", true)
	anim.play("Dead")



func input_movement(delta: float) -> void:
	input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input * speed

	if input > 0:
		set_facing(1)
	elif input < 0:
		set_facing(-1)

	if is_on_floor():
		jump_count = 0
		wall_jump_count = 0
		is_wall_sliding = false
		can_dash = true
	else:
		apply_gravity(delta)

	if can_wall_slide():
		is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)
	else:
		is_wall_sliding = false

	if Input.is_action_just_pressed("ui_accept"):
		if can_wall_jump():
			wall_jump()
			return

		if jump_count < max_jump:
			jump_count += 1
			velocity.y = -jump_force

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5


func start_dash() -> void:
	if is_dead or is_attacking or current_state == PlayerStates.HIT or not can_dash:
		return

	can_dash = false
	is_invincible = true
	current_state = PlayerStates.DASH
	is_wall_sliding = false
	set_collision_mask_value(ENEMY_BODY_LAYER, false)

	var dash_direction := facing
	if input != 0:
		dash_direction = sign(input)

	velocity.x = dash_direction * dash_speed
	velocity.y = 0

	await get_tree().create_timer(dash_time).timeout

	if is_dead:
		set_collision_mask_value(ENEMY_BODY_LAYER, true)
		return

	is_invincible = false
	current_state = PlayerStates.MOVE
	set_collision_mask_value(ENEMY_BODY_LAYER, true)

	await get_tree().create_timer(dash_cooldown).timeout

	if is_on_floor():
		can_dash = true


func take_damage(amount: int = 10) -> void:
	if is_dead or is_invincible or amount <= 0:
		return

	player_data.life = maxi(0, player_data.life - player_data.incoming_damage(amount))
	if player_data.life <= 0:
		start_dead()
		return
	current_state = PlayerStates.HIT
	is_attacking = false
	is_wall_sliding = false
	is_invincible = true
	velocity.x = 0
	sword_collider.set_deferred("disabled", true)
	anim.play("Hit")


func set_facing(direction: int) -> void:
	facing = direction
	sprite.flip_h = direction < 0
	$sword.scale.x = direction
	wall.scale.x = direction


func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta


func can_wall_slide() -> bool:
	return not is_on_floor() and wall_collider() and input == facing and velocity.y > 0


func can_wall_jump() -> bool:
	return not is_on_floor() and wall_collider() and wall_jump_count < max_wall_jump


func wall_jump() -> void:
	var jump_direction := -facing

	if input == jump_direction:
		velocity.x = jump_direction * wall_jump_push
	else:
		velocity.x = jump_direction * wall_jump_short_push

	velocity.y = -wall_jump_force
	wall_jump_count += 1
	jump_count = 1
	is_wall_sliding = false


func start_sword_attack() -> void:
	if is_attacking or is_dead or current_state == PlayerStates.HIT:
		return

	is_attacking = true
	current_state = PlayerStates.SWORD
	sword_hit_targets.clear()

	sword_collider.set_deferred("disabled", false)
	anim.play("Sword")


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		&"Dead":
			if is_dead:
				player_data.execute_roguelike_loop(self)
		&"Hit":
			if current_state == PlayerStates.HIT and not is_dead:
				is_invincible = false
				reset_states()
				update_animation()
		&"Sword":
			if current_state == PlayerStates.SWORD and not is_dead:
				sword_collider.set_deferred("disabled", true)
				reset_states()


func check_sword_hits() -> void:
	if not is_attacking or sword_collider.disabled:
		return

	for area: Area2D in sword_area.get_overlapping_areas():
		var target: Node = area.get_parent()

		if target == null or target in sword_hit_targets:
			continue

		if target.has_method("take_damage"):
			sword_hit_targets.append(target)
			target.take_damage(sword_damage)


func wall_collider() -> bool:
	return wall.is_colliding()


func reset_states() -> void:
	if is_dead:
		return

	is_attacking = false
	current_state = PlayerStates.MOVE


func update_animation() -> void:
	if current_state != PlayerStates.MOVE:
		return

	if is_wall_sliding:
		anim.play("Fall")
	elif not is_on_floor():
		if velocity.y < 0:
			anim.play("Jump")
		else:
			anim.play("Fall")
	elif input != 0:
		anim.play("Walk")
	else:
		anim.play("Idle")
