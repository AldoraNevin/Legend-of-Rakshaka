extends MarginContainer

func _on_deadzone_changed(value: float) -> void:
	AppSettings.apply_controller_deadzone(value)
