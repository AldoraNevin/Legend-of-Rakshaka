extends Control
const IDLE := preload("res://Assets/Legend of Rakshaka/Skill_UI/Skill idle animation.png")
const CHARGE := preload("res://Assets/Legend of Rakshaka/Skill_UI/skill charge.png")
var elapsed := 0.0

func _ready() -> void:
	position = Vector2(16, 66)
	size = Vector2(72, 68)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Pemulihan [R] / tap: +10 HP. Jeda 3 detik antar pemakaian."

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var ready := player_data.skill_charges > 0
	var texture: Texture2D = IDLE if ready else CHARGE
	var frame := int(elapsed / 0.1) % 6 if ready else clampi(int((1.0 - player_data.skill_recharge_left / player_data.healing_cooldown()) * 4), 0, 4)
	draw_texture_rect_region(texture, Rect2(6, 0, 52, 54), Rect2(frame * 133, 0, 133, 157))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 14), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f5dd96"))
	draw_string(font, Vector2(43, 49), "%d/%d" % [player_data.skill_charges, player_data.healing_capacity()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	var wait := player_data.skill_interval_left if ready else player_data.skill_recharge_left
	var text := "%.1fs" % wait if wait > 0 else "+10 HP"
	draw_string(font, Vector2(9, 66), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7fffea"))

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		HealingSkill.use_skill()
		accept_event()
