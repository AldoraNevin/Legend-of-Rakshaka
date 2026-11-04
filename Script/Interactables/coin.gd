extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$anim.play("Active")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$anim.play("Destroyed")
		player_data.coin += 1
		print("Coin Collected : ", player_data.coin)
		await $anim.animation_finished
		queue_free()
