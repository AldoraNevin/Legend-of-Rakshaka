extends CharacterBody2D
## Scene-owned boss: the stage tracks its lifetime to unlock the exit.
@export var max_health := 600
@export var damage := 18
@export var attack_cooldown := 2.0
@export var gravity := 1000.0
var health: float
var is_dead := false
var cooldown_left := 1.5
var casting := false
var player: Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("artifact_enemies")
	health = max_health
	$AnimationPlayer.stop()
	# SpriteFrames are shared between instances; keep loop changes local.
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for clip in [&"RainSpear", &"Dead"]:
		sprite.sprite_frames.set_animation_loop(clip, false)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"Idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if preload("res://Script/Enemies/artifact_status.gd").tick(self, delta):
		sprite.pause()
		return
	if not sprite.is_playing():
		sprite.play()
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if not casting and cooldown_left == 0.0:
		casting = true
		sprite.play(&"RainSpear")

func _on_animation_finished() -> void:
	if is_dead:
		queue_free()
	elif casting:
		casting = false
		cooldown_left = attack_cooldown
		if is_instance_valid(player):
			var spear := Spear.new()
			spear.target = player
			spear.boss = self
			spear.damage = damage
			add_child(spear)
			spear.global_position = global_position + Vector2(0, -30)
			spear.direction = (player.global_position - spear.global_position).normalized()
		sprite.play(&"Idle")

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0:
		return
	health = maxf(0.0, health - amount)
	if health == 0:
		is_dead = true
		$Hurtbox.set_deferred("monitorable", false)
		sprite.play(&"Dead")

class Spear extends Node2D:
	var target: Node2D
	var boss: Node2D
	var direction := Vector2.ZERO
	var damage := 18
	var lifetime := 4.0
	var spent := false

	func _ready() -> void:
		top_level = true
		var visual := AnimatedSprite2D.new()
		visual.sprite_frames = boss.get_node("AnimatedSprite2D").sprite_frames
		visual.scale = Vector2.ONE * 0.3
		add_child(visual)
		visual.play(&"ProyektilRainSpear")

	func _physics_process(delta: float) -> void:
		if spent:
			return
		lifetime -= delta
		if lifetime <= 0 or not is_instance_valid(target) or boss.is_dead:
			queue_free()
			return
		var next := global_position + direction * 220.0 * delta
		var query := PhysicsRayQueryParameters2D.create(global_position, next, 3)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			spent = true
			if hit.collider == target and target.has_method("take_damage"):
				target.take_damage(damage, boss, true)
			queue_free()
		else:
			global_position = next
