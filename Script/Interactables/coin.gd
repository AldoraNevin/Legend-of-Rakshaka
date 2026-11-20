extends Area2D
var collected := false
func _ready() -> void:
	var texture: Texture2D = $Sprite2D.texture
	$Sprite2D.scale = Vector2.ONE * (20.0 / maxf(texture.get_width(), texture.get_height()))
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not collected:
		collected = true
		$CollisionShape2D.set_deferred("disabled", true)
		player_data.add_gold(1)
		var fade := create_tween().set_parallel(true)
		fade.tween_property(self, "modulate:a", 0.0, 0.2)
		fade.tween_property($Sprite2D, "position:y", -14.0, 0.2)
		await fade.finished
		queue_free()
