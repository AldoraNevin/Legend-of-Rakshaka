extends "res://Script/Interactables/coastal_treasure.gd"
## Artifact branches unlock the existing artifact catalog; treasure gives coins.
const PEDESTAL_TEXTURE := preload("res://Legend of Rakshaka/Environment/Decoration/Dudukan arte dan peti.png")
const ARTIFACT_SCENE_DIR := "res://Scenes/Artefak/"
@export_enum("treasure", "artifact") var reward_kind := "treasure"
@export var artifact_name := "Daun Kelor"
## Sisi terpanjang artefak di dalam level (px). Skala dihitung otomatis dari ukuran frame,
## jadi artefak 64x64 maupun yang lebih besar (mis. Mustika Merah Delima) tampil sama besar.
@export var artifact_visual_size := 32.0
@export var artifact_visual_offset := Vector2(0, -38)
var artifact_visual: Node2D

## "Daun Kelor" -> res://Scenes/Artefak/DaunKelor.tscn
static func artifact_scene_path(display_name: String) -> String:
	return ARTIFACT_SCENE_DIR + display_name.replace(" ", "") + ".tscn"

static func has_artifact_scene(display_name: String) -> bool:
	return ResourceLoader.exists(artifact_scene_path(display_name))

func _ready() -> void:
	super._ready()
	add_to_group("level_rewards")
	if reward_kind == "artifact":
		prompt.text = "[E] Ambil artefak"
		prompt.position.y = -74
		prompt.modulate = Color(0.65, 0.85, 1.0)
		_spawn_artifact_visual()

## Menampilkan scene artefak buatan (animasi Float/Idle) di atas altar.
## Artefak tanpa scene tetap memakai berlian placeholder di _draw().
func _spawn_artifact_visual() -> void:
	var path := artifact_scene_path(artifact_name)
	if not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	if scene == null:
		return
	artifact_visual = scene.instantiate() as Node2D
	if artifact_visual == null:
		return
	artifact_visual.position = artifact_visual_offset
	artifact_visual.scale = Vector2.ONE * _fit_scale(artifact_visual)
	# Hanya visual: pengambilan tetap lewat tombol interaksi, bukan area sentuh.
	artifact_visual.set_deferred("monitoring", false)
	add_child(artifact_visual)
	_ensure_animating(artifact_visual)
	queue_redraw()

## Memastikan animasi artefak benar-benar jalan walau autoplay/loop di scene belum diatur.
func _ensure_animating(visual: Node) -> void:
	var player := visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		var wanted: StringName = &""
		if player.has_animation(&"Float"):
			wanted = &"Float"
		else:
			for anim_name in player.get_animation_list():
				if anim_name != &"RESET":
					wanted = anim_name
					break
		if wanted != &"":
			player.get_animation(wanted).loop_mode = Animation.LOOP_LINEAR
			if not player.is_playing() or player.current_animation != wanted:
				player.play(wanted)
			return
	var sprite := visual.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
		sprite.sprite_frames.set_animation_loop(sprite.animation, true)
		sprite.play(sprite.animation)

func _fit_scale(visual: Node) -> float:
	var sprite := visual.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation):
		return 0.5
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if frame == null:
		return 0.5
	return artifact_visual_size / maxf(frame.get_width(), frame.get_height())

func _draw() -> void:
	if reward_kind == "treasure":
		super._draw()
		return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	draw_texture_rect(PEDESTAL_TEXTURE, Rect2(-24, -20, 48, 36), false)
	if not opened and artifact_visual == null:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -49), Vector2(9, -38), Vector2(0, -27), Vector2(-9, -38)]), Color(0.35, 0.85, 1.0))
		draw_circle(Vector2(0, -38), 3, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
	if reward_kind != "artifact":
		super._unhandled_input(event)
		return
	if opened or not event.is_action_pressed("ui_interact") or event.is_echo():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or absf(player.global_position.x - global_position.x) > 42 or absf(player.global_position.y - global_position.y) > 32:
		return
	opened = true
	player.collect_artifact(artifact_name)
	prompt.text = artifact_name + " ditemukan"
	if artifact_visual != null:
		artifact_visual.hide()
	queue_redraw()
	get_viewport().set_input_as_handled()
