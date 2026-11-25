@tool
extends AnimatedSprite2D
## Visual-only corrections, in source pixels. Idle is the size reference.
## Keep physics shapes on Player, outside this node's transform.

const ANIMATION_SCALE := {
	&"Idle": 1.0, &"Walk": 1.0,
	&"Attack1": 0.68, &"Attack2": 0.68, &"Attack3": 0.68,
	&"Dash": 0.86, &"Dead": 0.95, &"Drop": 1.0,
	&"Hit": 0.83, &"Jump": 1.0, &"Wall": 0.85,
}
const ANIMATION_OFFSET := {
	&"Idle": Vector2.ZERO, &"Walk": Vector2.ZERO,
	&"Attack1": Vector2(6, 12),
	&"Attack2": Vector2(6, 11),
	&"Attack3": Vector2(6, 8),
	&"Dash": Vector2(-24, 26),
	&"Dead": Vector2(0, 10),
	&"Drop": Vector2(0, 12),
	&"Hit": Vector2(0, -5),
	&"Jump": Vector2(0, 0),
	&"Wall": Vector2(0, 0),
}


var extended_slash: Sprite2D
var swing_material: ShaderMaterial
var trail_material: ShaderMaterial

func _ready() -> void:
	if not Engine.is_editor_hint():
		swing_material = ShaderMaterial.new()
		swing_material.shader = preload("res://Script/Player/slash_artifact.gdshader")
		trail_material = swing_material.duplicate()
		trail_material.set_shader_parameter("slash_only", true)
		extended_slash = Sprite2D.new()
		extended_slash.material = trail_material
		extended_slash.show_behind_parent = true
		add_child(extended_slash)
		frame_changed.connect(_sync_slash)

	animation_changed.connect(apply_animation_transform)
	apply_animation_transform()


func apply_animation_transform() -> void:
	var factor: float = ANIMATION_SCALE.get(animation, 1.0)
	scale = Vector2.ONE * factor
	# AnimatedSprite2D mirrors the drawing offset together with flip_h.
	offset = ANIMATION_OFFSET.get(animation, Vector2.ZERO)
	_sync_slash()

func _sync_slash() -> void:
	if extended_slash == null:
		return
	var attacking := animation in [&"Attack1", &"Attack2", &"Attack3"]
	extended_slash.visible = attacking and player_data.has_artifact("tombak_baru_klinting")
	var red := attacking and (player_data.has_artifact("gadha_rujakpolo") or player_data.has_artifact("jimat_kalimasada") or player_data.has_artifact("golok_jakasembung") or (player_data.has_artifact("rencong_sakti") and player_data.life <= player_data.max_life * 0.3))
	material = swing_material if red else null
	swing_material.set_shader_parameter("crimson", red)
	if extended_slash.visible:
		trail_material.set_shader_parameter("crimson", red)
		extended_slash.texture = sprite_frames.get_frame_texture(animation, frame)
		extended_slash.flip_h = flip_h
		extended_slash.offset = offset
		extended_slash.scale = Vector2(1.5, 1)
