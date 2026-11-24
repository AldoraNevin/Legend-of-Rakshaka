extends Control
const IDLE := preload("res://Assets/Legend of Rakshaka/Skill_UI/Skill idle animation.png")
const CHARGE := preload("res://Assets/Legend of Rakshaka/Skill_UI/skill charge.png")
var elapsed := 0.0

func _ready() -> void:
	position = Vector2(16, 66)
	size = Vector2(56, 54)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Pemulihan / tap: +10 HP."

func _process(delta: float) -> void:
	size.x = 12 + 44 * player_data.healing_capacity()
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var charges := player_data.skill_charges
	var fill := clampf(1.0 - player_data.skill_recharge_left / player_data.healing_cooldown(), 0.0, 1.0)
	for slot in range(player_data.healing_capacity()):
		var lit := slot < charges
		var texture := IDLE if lit else CHARGE
		var frame := int(elapsed * 10) % 6 if lit else (mini(4, int(fill * 5)) if slot == charges else 0)
		var tint := Color.WHITE
		if lit and player_data.skill_interval_left > 0:
			tint = Color.WHITE.darkened(0.5 * player_data.skill_interval_left / 3.0)
		elif not lit and slot > charges:
			tint = Color.WHITE.darkened(0.55)
		draw_texture_rect_region(texture, Rect2(6 + 44 * slot, 0, 44, 52), Rect2(frame * 133, 0, 133, 157), tint)
	draw_string(preload("res://Assets/Fonts/PixelifySans/PixelifySans.ttf"), Vector2(0, 14), _binding_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f5dd96"))

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		HealingSkill.use_skill()
		accept_event()

func _binding_label() -> String:
	var bindings := InputMap.action_get_events("heal_skill")
	return bindings[0].as_text().trim_suffix(" (Physical)") if not bindings.is_empty() else ""
