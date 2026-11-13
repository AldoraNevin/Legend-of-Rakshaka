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


func _ready() -> void:
	animation_changed.connect(apply_animation_transform)
	apply_animation_transform()


func apply_animation_transform() -> void:
	var factor: float = ANIMATION_SCALE.get(animation, 1.0)
	scale = Vector2.ONE * factor
	# AnimatedSprite2D mirrors the drawing offset together with flip_h.
	offset = ANIMATION_OFFSET.get(animation, Vector2.ZERO)
