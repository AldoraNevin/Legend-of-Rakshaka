extends CharacterBody2D
## Scene-owned boss: the stage tracks its lifetime to unlock the exit.
@export var max_health := 1000
@export var damage := 48
@export var attack_cooldown := 2.0
@export var gravity := 1000.0
const CASTS := [&"RainSpear", &"TidalWall", &"WaterCastingFortex"]
const FOOT_OFFSETS := {&"Idle": -5, &"Dead": -5, &"RainSpear": -5, &"TidalWall": -5, &"WaterCastingFortex": -17}
const RAIN_COUNT := 24
const RAIN_INTERVAL := 0.18
var overhead_rain := false
var rain_left := 0
var rain_delay := 0.0
var pressure_hits := 0
var pressure_window := 0.0
var countering := false
var released := false
var flash: Tween
@onready var health_hud := preload("res://Scenes/UI/boss_health_hud.tscn").instantiate() as CanvasLayer
var health: float
var is_dead := false
var cooldown_left := 1.5
var casting := false
var player: Node2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("artifact_enemies")
	add_child(health_hud)
	health_hud.get_node("Health").max_value = max_health
	health_hud.get_node("Health").value = max_health
	health = max_health
	position.y -= 123.0 * scale.y - 45.6
	$AnimationPlayer.stop()
	# SpriteFrames are shared between instances; keep loop changes local.
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for clip in CASTS + [&"Dead"]:
		sprite.sprite_frames.set_animation_loop(clip, false)
	sprite.animation_changed.connect(_ground_sprite)
	_ground_sprite()
	sprite.frame_changed.connect(_release_cast)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"Idle")

func _ground_sprite() -> void:
	sprite.position.y = FOOT_OFFSETS.get(sprite.animation, 0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	pressure_window = maxf(0, pressure_window - delta)
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
	if rain_left > 0:
		rain_delay -= delta
		if rain_delay <= 0.0:
			rain_left -= 1
			rain_delay += RAIN_INTERVAL
			_spawn_rain_spear()
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if not casting and cooldown_left == 0.0:
		casting = true
		released = false
		sprite.flip_h = player.global_position.x > global_position.x
		var cast: StringName = CASTS.pick_random()
		sprite.play(cast, 1.6 if cast == &"RainSpear" else 1.0)

func _on_animation_finished() -> void:
	if not is_dead and casting:
		casting = false
		countering = false
		cooldown_left = attack_cooldown
		sprite.play(&"Idle")

func _release_cast() -> void:
	if is_dead or not casting or released or sprite.frame != 10 or not is_instance_valid(player):
		return
	released = true
	if sprite.animation == &"RainSpear":
		overhead_rain = randf() < 0.5
		rain_left = RAIN_COUNT
		rain_delay = 0.0
		return
	var attack := WaterAttack.new()
	attack.kind = sprite.animation
	attack.target = player
	attack.damage = damage
	add_child(attack)
	attack.launch(global_position + Vector2.DOWN * 123.0 * global_scale.y)

func _spawn_rain_spear() -> void:
	var aim := player.global_position
	if overhead_rain:
		# Lead ordinary movement, then leave each visible lane fixed for dodging.
		aim.x += clampf(player.velocity.x, -160.0, 160.0) * 0.42
		aim.x += [0.0, -60.0, 60.0, -30.0, 30.0][rain_left % 5]
	var query := PhysicsRayQueryParameters2D.create(aim, aim + Vector2.DOWN * 2000.0, 2)
	var floor_hit := get_world_2d().direct_space_state.intersect_ray(query)
	if floor_hit.is_empty():
		return
	var floor_point: Vector2 = floor_hit.position
	var spear := RainSpear.new()
	spear.top_level = true
	spear.z_index = 3
	spear.texture = preload("res://Legend of Rakshaka/boss/nyi roro kidul/Turquoise Rain Spear Impact Sprite Sheet-5-sheet.png")
	spear.hframes = 12
	spear.damage = damage
	spear.target = player
	spear.overhead = overhead_rain
	spear.origin = floor_point + Vector2.DOWN * 50.0
	spear.apex = aim + Vector2.UP * 110.0
	if overhead_rain:
		# Keep the first droplet inside the visible arena even when the player jumps.
		var screen_top := (get_canvas_transform().affine_inverse() * get_viewport_rect().position).y
		spear.apex.y = maxf(spear.apex.y, screen_top + 44.0)
	add_child(spear)
	spear.global_transform = Transform2D(0.0 if overhead_rain else PI, Vector2.ONE * 0.23, 0.0, spear.apex if overhead_rain else spear.origin)
	spear.reset_physics_interpolation()

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0:
		return
	if flash:
		flash.kill()
	sprite.self_modulate = Color(1, 0.12, 0.12)
	flash = create_tween()
	flash.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)
	health = maxf(0.0, health - amount)
	health_hud.get_node("Health").value = health
	if health == 0:
		health_hud.hide()
		is_dead = true
		var victor := get_tree().get_first_node_in_group("player")
		if victor != null and victor.has_method("on_boss_victory"):
			victor.on_boss_victory(self)
		player_data.discover_enemy("nyi_roro_kidul")
		$Hurtbox.set_deferred("monitorable", false)
		_play_defeat()
	elif not casting and not countering:
		pressure_hits = pressure_hits + 1 if pressure_window > 0 else 1
		pressure_window = 1.0
		if pressure_hits >= 3 and is_instance_valid(player):
			pressure_hits = 0
			countering = true
			casting = true
			released = false
			set_meta("stun_left", 0.0)
			sprite.flip_h = player.global_position.x > global_position.x
			var counter: StringName = [&"RainSpear", &"WaterCastingFortex"].pick_random()
			sprite.play(counter, 1.6 if counter == &"RainSpear" else 1.3)

func _play_defeat() -> void:
	var music := get_parent().get_node_or_null("RoomMusic") as AudioStreamPlayer
	if music == null:
		music = AudioStreamPlayer.new()
		music.bus = "Music"
		music.volume_db = -12
		get_parent().add_child(music)
	music.set_process(false)
	if music.playing:
		var transition := create_tween()
		transition.tween_property(music, "volume_db", -52.0, 0.35)
		await transition.finished
	music.volume_db = -12
	music.stream = preload("res://Legend of Rakshaka/BGM/Outro Boss.ogg")
	music.play()
	var frames := sprite.sprite_frames
	var duration := frames.get_frame_count(&"Dead") / frames.get_animation_speed(&"Dead")
	sprite.play(&"Dead", duration / maxf(0.01, music.stream.get_length()))
	var previous := get_viewport().get_camera_2d()
	if previous == null:
		await music.finished
		queue_free()
		return
	var focus := Camera2D.new()
	focus.top_level = true
	add_child(focus)
	focus.global_position = previous.get_screen_center_position()
	focus.zoom = previous.zoom
	focus.make_current()
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(-4000,-3000), Vector2(4000,-3000), Vector2(4000,3000), Vector2(-4000,3000)])
	shade.color = Color(0.01, 0.07, 0.11, 0)
	shade.z_index = 9
	add_child(shade)
	sprite.z_index = 10
	var shot := create_tween().set_trans(Tween.TRANS_SINE)
	shot.tween_property(focus, "global_position", global_position, 0.45)
	shot.parallel().tween_property(focus, "zoom", previous.zoom * 1.18, 0.45)
	shot.parallel().tween_property(shade, "color:a", 0.67, 0.45)
	await music.finished
	if is_instance_valid(previous):
		var release := create_tween().set_trans(Tween.TRANS_SINE)
		release.tween_property(shade, "color:a", 0.0, 0.4)
		release.parallel().tween_property(focus, "global_position", previous.global_position + previous.offset, 0.4)
		release.parallel().tween_property(focus, "zoom", previous.zoom, 0.4)
		await release.finished
		previous.make_current()
	queue_free()

class WaterAttack extends Node2D:
	var kind: StringName
	var target: Node2D
	var damage: int
	var age := 0.0
	var heading: float
	var effect: Sprite2D
	var spent := false
	var eruption_height := 180.0

	func launch(feet: Vector2) -> void:
		top_level = true
		global_transform = Transform2D(0, feet)
		z_index = 3
		heading = 1.0 if target.global_position.x >= feet.x else -1.0
		effect = Sprite2D.new()
		if kind == &"WaterCastingFortex":
			global_position.x = target.global_position.x
			effect.texture = preload("res://Legend of Rakshaka/boss/nyi roro kidul/Undertow Vortex and Geyser Sprite Sheet-6-sheet.png")
		else:
			effect.texture = preload("res://Legend of Rakshaka/boss/nyi roro kidul/Pixel art tidal wall sprite sheet-4-sheet.png")
		effect.hframes = 12
		effect.scale = Vector2.ONE * 0.45
		effect.position.y = -50
		add_child(effect)

	func _physics_process(delta: float) -> void:
		age += delta
		if not is_instance_valid(target) or get_parent().get("is_dead"):
			queue_free()
			return
		var active := false
		var height := 0.0
		if kind == &"TidalWall":
			# The leading crest gathers at the boss before sweeping the floor.
			var charge := clampf(age / 0.32, 0.0, 1.0)
			height = 58.0 * charge
			effect.scale = Vector2(0.50, 0.29) * charge
			effect.flip_h = heading > 0
			active = age >= 0.32
			if active:
				global_position.x += heading * minf(510, 260 + age * 160) * delta
			effect.frame = mini(int(charge * 3), 3) if not active else 3 + int((age - 0.32) * 30) % 8
			if age >= 3.8:
				queue_free()
		else:
			# Lock the geyser to the platform under the player before it erupts.
			if age < 0.38:
				var aim := target.global_position
				var query := PhysicsRayQueryParameters2D.create(aim, aim + Vector2.DOWN * 2000, 2)
				var hit := get_world_2d().direct_space_state.intersect_ray(query)
				if not hit.is_empty():
					global_position = hit.position
					eruption_height = maxf(180.0, global_position.y - aim.y + 90.0)
			var surge := clampf((age - 0.55) / 0.10, 0.0, 1.0)
			var fade := clampf((1.35 - age) / 0.25, 0.0, 1.0)
			height = (10 + eruption_height * surge) * fade
			effect.scale = Vector2(0.52, height / 224.0)
			effect.frame = mini(int(age * 6), 3) if age < 0.55 else mini(4 + int((age - 0.55) * 15), 11)
			active = surge > 0.1 and fade > 0.1
			if age >= 1.35:
				queue_free()
		effect.position.y = -effect.scale.y * 128
		var offset := target.global_position - global_position
		if active and not spent and absf(offset.x) < 42 and offset.y >= -height and offset.y <= 10:
			spent = true
			target.take_damage(damage, get_parent(), true)

class RainSpear extends Sprite2D:
	var overhead := false
	const RISE := 0.55
	const TURN := 0.20
	var target: Node2D
	var damage: int
	var origin: Vector2
	var apex: Vector2
	var age := 0.0
	var impact_age := -1.0

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(target) or get_parent().get("is_dead"):
			queue_free()
			return
		age += delta
		if impact_age >= 0.0:
			impact_age += delta
			frame = mini(8 + int(impact_age * 15), 11)
			if impact_age >= 4.0 / 15.0:
				queue_free()
		elif overhead and age < 0.32:
			frame = mini(int(age / 0.04), 7)
		elif not overhead and age < RISE:
			global_position = origin.lerp(apex, age / RISE)
			frame = mini(int(age / RISE * 5), 4)
		elif not overhead and age < RISE + TURN:
			global_position = apex
			rotation = lerpf(PI, 0.0, (age - RISE) / TURN)
			frame = 5
		else:
			rotation = 0.0
			frame = 7 if overhead else 6
			var tip := global_position + Vector2.DOWN * 32
			var travel := Vector2.DOWN * (760.0 if overhead else 490.0) * delta
			var ray := PhysicsRayQueryParameters2D.create(tip, tip + travel, 3)
			ray.hit_from_inside = true
			var hit := get_world_2d().direct_space_state.intersect_ray(ray)
			if hit.is_empty():
				global_position += travel
				if age > 5:
					queue_free()
				return
			global_position = hit.position - Vector2.DOWN * 33
			impact_age = 0.0
			frame = 8
			if hit.collider == target:
				target.take_damage(damage, get_parent(), true)
