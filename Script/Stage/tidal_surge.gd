extends Node2D
## Telegraph -> short water burst -> recovery. Jump or wait on a balcony.
var elapsed := 0.0
var struck := false
func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 8.0:
		elapsed = 0.0
		struck = false
	if elapsed >= 5.5 and elapsed < 6.5 and not struck:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and Rect2(-72, -40, 144, 40).has_point(to_local(player.global_position)):
			if player.has_method("take_damage"):
				player.take_damage(1)
			struck = true
	queue_redraw()
func _draw() -> void:
	if elapsed >= 4.0 and elapsed < 5.5:
		draw_rect(Rect2(-72, -3, 144, 3), Color(0.9, 0.8, 0.35, 0.8))
	elif elapsed >= 5.5 and elapsed < 6.5:
		draw_rect(Rect2(-72, -40, 144, 40), Color(0.15, 0.7, 0.72, 0.65))
