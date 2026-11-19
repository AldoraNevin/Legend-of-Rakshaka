extends CharacterBody2D

enum PlayerStates { MOVE, SWORD, DEAD, DASH, HIT }

const ENEMY_BODY_LAYER := 5
const MAX_COMBO := 3

const LOCK_MOVE_FROM_STEP := 1

var regeneration_time := 0.0
var negative_effects: Dictionary = {}
var shockwave_left := 0.0
var shockwave_fired := false
var sword_base_scale := Vector2.ONE

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

# Combo serangan
var combo_step := 0
var combo_queued := false

var current_state := PlayerStates.MOVE

@export var speed := 100.0
@export var gravity := 1000.0

@export var max_jump := 1
## Empty means locked. Set to a bestiary artifact ID/name when that reward is chosen.
@export var double_jump_artifact_id := "selendang_bidadari"
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
# Damage tambahan khusus serangan ke-3 (0 = sama seperti serangan biasa)
@export var combo_finisher_bonus := 0

@onready var wall: RayCast2D = $wall_ray
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $sword
@onready var sword_collider: CollisionShape2D = $sword/Sword_Collider


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_update_sword_window)
	sprite.play("Idle")
	add_to_group("player")
	sword_base_scale = sword_area.scale
	refresh_artifact_stats()
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(50)
	sword_area.add_to_group("player_sword")
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(ENEMY_BODY_LAYER, true)
	sword_collider.disabled = true


func _physics_process(delta: float) -> void:
	_tick_artifacts(delta)
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
	input_movement(delta, combo_step < LOCK_MOVE_FROM_STEP)

	if Input.is_action_just_pressed("ui_sword") and combo_step < MAX_COMBO:
		combo_queued = true

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
	combo_step = 0
	combo_queued = false
	current_state = PlayerStates.DEAD
	sword_collider.set_deferred("disabled", true)
	sprite.play("Dead")


func input_movement(delta: float, can_move := true) -> void:
	input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	if can_move:
		velocity.x = input * speed
		if input > 0:
			set_facing(1)
		elif input < 0:
			set_facing(-1)
	else:
		velocity.x = 0

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
		try_jump()

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5

func refresh_jump_ability() -> void:
	max_jump = 2 if CheatCodes.double_jump or player_data.has_artifact(double_jump_artifact_id) else 1
	# Walking off a ledge consumes the ground jump, preventing an extra mid-air jump.
	if not is_on_floor():
		jump_count = maxi(jump_count, 1)

func try_jump() -> bool:
	if can_wall_jump():
		wall_jump()
		return true
	refresh_jump_ability()
	if is_on_floor() or (max_jump > 1 and jump_count < max_jump):
		if is_on_floor():
			jump_count = 0
		jump_count += 1
		velocity.y = -jump_force
		return true
	return false


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

	sprite.play("Dash")
	velocity.x = dash_direction * dash_speed
	velocity.y = 0

	await get_tree().create_timer(dash_time * (1.5 if not is_on_floor() and player_data.has_artifact("selendang_bidadari") else 1.0)).timeout

	if is_dead:
		set_collision_mask_value(ENEMY_BODY_LAYER, true)
		return

	is_invincible = false
	current_state = PlayerStates.MOVE
	set_collision_mask_value(ENEMY_BODY_LAYER, true)

	update_animation()
	await get_tree().create_timer(dash_cooldown).timeout

	if is_on_floor():
		can_dash = true


func take_damage(amount: int = 10, source: Node = null, projectile := false) -> void:
	if is_dead or is_invincible or CheatCodes.god_mode or amount <= 0:
		return

	var damage := player_data.incoming_damage(amount, projectile)
	if damage >= player_data.life and player_data.has_artifact("mustika_merah_delima") and not player_data.fatal_shield_used:
		player_data.fatal_shield_used = true
		player_data.save_to_json()
		return
	player_data.life = maxi(0, player_data.life - damage)
	if player_data.has_artifact("kujang_pusaka") and is_instance_valid(source) and source.has_method("take_damage"):
		source.take_damage(maxi(1, ceili(damage * 0.3)))
	if player_data.life <= 0:
		start_dead()
		return
	current_state = PlayerStates.HIT
	is_attacking = false
	combo_step = 0
	combo_queued = false
	is_wall_sliding = false
	is_invincible = true
	velocity.x = 0
	sword_collider.set_deferred("disabled", true)
	sprite.play("Hit")


func set_facing(direction: int) -> void:
	facing = direction
	sprite.flip_h = direction < 0
	$sword.scale.x = direction * sword_base_scale.x * (1.5 if player_data.has_artifact("tombak_baru_klinting") else 1.0)
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
	combo_step = 1
	combo_queued = false
	play_attack(combo_step)


func play_attack(step: int) -> void:
	shockwave_fired = false
	sword_hit_targets.clear()
	sword_collider.set_deferred("disabled", true)
	sprite.play("Attack%d" % step, 1.5)
	_update_sword_window()


func end_combo() -> void:
	combo_step = 0
	combo_queued = false
	sword_collider.set_deferred("disabled", true)
	reset_states()
	update_animation()


func _update_sword_window() -> void:
	if not is_attacking or current_state != PlayerStates.SWORD:
		return
	var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
	# Wind-up and recovery do not deal damage; only the middle swing frames do.
	var active := sprite.frame > 0 and sprite.frame < frame_count - 1
	sword_collider.set_deferred("disabled", not active)


func _on_animation_finished() -> void:
	match sprite.animation:
		&"Dead":
			if is_dead:
				player_data.execute_roguelike_loop(self)
		&"Hit":
			if current_state == PlayerStates.HIT and not is_dead:
				is_invincible = false
				reset_states()
				update_animation()
		&"Attack1", &"Attack2", &"Attack3":
			if current_state != PlayerStates.SWORD or is_dead:
				return

			if combo_queued and combo_step < MAX_COMBO:
				combo_step += 1
				combo_queued = false
				play_attack(combo_step)
			else:
				end_combo()


func check_sword_hits() -> void:
	if not is_attacking or sword_collider.disabled:
		return

	var damage := sword_damage
	if combo_step == MAX_COMBO:
		damage += combo_finisher_bonus

	if player_data.has_artifact("pecut_samandiman") and not shockwave_fired:
		shockwave_fired = true
		shockwave_left = 0.18
		queue_redraw()
		for enemy in get_tree().get_nodes_in_group("artifact_enemies"):
			var offset: Vector2 = enemy.global_position - global_position
			if offset.x * facing >= 0 and offset.x * facing <= 120 and absf(offset.y) <= 45:
				_hit_artifact_target(enemy, damage)
	for area: Area2D in sword_area.get_overlapping_areas():
		var target: Node = area.get_parent()

		if target == null or target in sword_hit_targets:
			continue

		if target.has_method("take_damage"):
			_hit_artifact_target(target, damage)


func wall_collider() -> bool:
	# Contact normals also work when the sprite/body scale makes the ray too short.
	return wall.is_colliding() or (is_on_wall_only() and get_wall_normal().x * facing < -0.5)


func reset_states() -> void:
	if is_dead:
		return

	is_attacking = false
	current_state = PlayerStates.MOVE


func update_animation() -> void:
	if current_state != PlayerStates.MOVE:
		return

	if is_wall_sliding:
		sprite.play("Wall")
	elif not is_on_floor():
		if velocity.y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Drop")
	elif input != 0:
		sprite.play("Walk")
	else:
		sprite.play("Idle")

func refresh_artifact_stats() -> void:
	player_data.apply_player_stats(self)
	set_facing(facing)

func collect_artifact(artifact_name: String) -> void:
	var old_max := player_data.max_life
	player_data.discover_artifact(artifact_name)
	refresh_artifact_stats()
	player_data.life = mini(player_data.max_life, player_data.life + maxi(0, player_data.max_life - old_max))
	if artifact_name in ["daun_kelor", "Daun Kelor"]:
		negative_effects.clear()
		player_data.life = mini(player_data.max_life, player_data.life + 20)
	player_data.save_to_json()

func _hit_artifact_target(target: Node, damage: int) -> void:
	if target in sword_hit_targets:
		return
	sword_hit_targets.append(target)
	preload("res://Script/Enemies/artifact_status.gd").apply(target,
		player_data.has_artifact("keris_mpu_gandring"),
		player_data.has_artifact("paku_emas") and randf() < 0.2)
	target.take_damage(player_data.melee_damage(damage, randf()))

## Shared entry point for enemy debuffs; Daun Kelor clears every entry.
func apply_negative_effect(kind: String, duration: float) -> void:
	negative_effects[kind] = {"remaining": duration, "tick": 1.0}

func _tick_artifacts(delta: float) -> void:
	if is_dead or player_data.life <= 0:
		return
	if shockwave_left > 0.0:
		shockwave_left = maxf(0.0, shockwave_left - delta)
		queue_redraw()
	for kind in negative_effects.keys():
		var effect: Dictionary = negative_effects[kind]
		effect.remaining -= delta
		effect.tick -= delta
		if kind in ["poison", "burn", "bleed"] and effect.tick <= 0.0:
			effect.tick += 1.0
			take_damage(1)
		if effect.remaining <= 0:
			negative_effects.erase(kind)
	if player_data.has_artifact("air_tirta_amerta"):
		regeneration_time += delta
		if regeneration_time >= 2.0:
			regeneration_time -= 2.0
			player_data.life = mini(player_data.max_life, player_data.life + 1)

func _draw() -> void:
	if shockwave_left > 0.0:
		var reach := 120.0 / maxf(absf(global_scale.x), 0.01)
		draw_line(Vector2(0, -8), Vector2(facing * reach, -8), Color(0.6, 0.9, 1.0, shockwave_left / 0.18), 4.0)
