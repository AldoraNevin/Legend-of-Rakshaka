extends Area2D
var collected := false
var elapsed := 0.0
const PULSE := [0, 1, 2, 3, 2, 1]
func _ready() -> void:
	var texture: Texture2D = $Sprite2D.texture
	$Sprite2D.scale = Vector2.ONE * (20.0 / maxf(texture.get_width() / 7.0, texture.get_height()))
func _process(delta: float) -> void:
	elapsed += delta
	$Sprite2D.frame = PULSE[int(elapsed / 0.14) % PULSE.size()]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not collected:
		collected = true
		set_process(false)
		$Sprite2D.frame = 3
		$CollisionShape2D.set_deferred("disabled", true)
		player_data.add_gold(1)
		var fade := create_tween().set_parallel(true)
		fade.tween_property(self, "modulate:a", 0.0, 0.42)
		fade.tween_property($Sprite2D, "position:y", -14.0, 0.42)
		fade.tween_property($Sprite2D, "frame", 6, 0.32)
		await fade.finished
		queue_free()
