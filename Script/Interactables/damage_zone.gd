extends Area2D

@export var current_state: spike_state
enum spike_state {ACTIVE, ANIMATED}

func _process(_delta: float) -> void:
	match current_state:
		spike_state.ACTIVE:
			active()
		spike_state.ANIMATED:
			active_animated()

func active():
	$anim.play("Active")
	
func active_animated():
	$anim.play("Active_animated")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_data.life -= 1
