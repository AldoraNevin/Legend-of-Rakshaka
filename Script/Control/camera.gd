extends Camera2D

@export var target: Node2D
@export var follow_speed := 6.0
@export var look_ahead := 40.0
@export var vertical_offset := -20.0

var target_offset := Vector2.ZERO


func _ready() -> void:
	make_current()
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	snap_to_target()


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D
		if target == null:
			return

	var input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	if input > 0:
		target_offset.x = look_ahead
	elif input < 0:
		target_offset.x = -look_ahead

	target_offset.y = vertical_offset

	var target_position := target.global_position + target_offset
	global_position = global_position.lerp(target_position, clampf(follow_speed * delta, 0.0, 1.0))


func snap_to_target() -> void:
	if target == null or not is_instance_valid(target):
		return

	target_offset.y = vertical_offset
	global_position = target.global_position + target_offset
	reset_smoothing()
