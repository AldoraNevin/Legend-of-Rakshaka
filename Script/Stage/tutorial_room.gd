extends Node2D

enum Step { WAITING, DIALOGUE, PRACTICE, REPORT, REPORT_DIALOGUE, COMPLETE }
@export var npc_name := "Semar"
@export var hostile_scene: PackedScene = preload("res://Scenes/Enemies/Aul.tscn")
var instructions: PackedStringArray:
	get:
		var pages := PackedStringArray()
		for line in $DialoguePages/Introduction.get_children():
			pages.append(line.text)
		return pages
var report_text: String:
	get:
		return $DialoguePages/Report.text
var step := Step.WAITING
var page := 0
var player: Node2D
var hostile: Node2D
var nearby := false
var previous_physics := true
var control_refresh_left := 0.0
@onready var dialogue: Control = $TutorialUI/Dialogue
@onready var body_text: Label = $TutorialUI/Dialogue/Margin/Content/Body
@onready var objective: Label = $TutorialUI/Objective

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	dialogue.hide()
	$GateHint.hide()
	$NPC/Prompt.hide()
	$NPC/Name.text = npc_name
	$NPC.body_entered.connect(_npc_entered)
	$NPC.body_exited.connect(_npc_exited)
	$TutorialUI/Dialogue/Margin/Content/Next.pressed.connect(advance_dialogue)
	refresh_control_text()

# Read the same live InputMap modified by the Controls menu.
func control_name(action: StringName) -> String:
	var keyboard_mouse: PackedStringArray = []
	var gamepad: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		var label: String
		if event is InputEventKey and DisplayServer.get_name() == "headless":
			var code = event.get_physical_keycode_with_modifiers() if event.physical_keycode else event.get_keycode_with_modifiers()
			label = OS.get_keycode_string(code).capitalize()
		else:
			label = InputEventHelper.get_device_specific_text(event)
		var labels = keyboard_mouse if event is InputEventKey or event is InputEventMouseButton else gamepad
		if not label.is_empty() and not label in labels:
			labels.append(label)
		if event is InputEventKey or event is InputEventMouseButton:
			keyboard_mouse = labels
		else:
			gamepad = labels
	var choices := keyboard_mouse if not keyboard_mouse.is_empty() else gamepad
	return " / ".join(choices) if not choices.is_empty() else "Belum diatur"

func instruction_text(text: String) -> String:
	for action in ["ui_left", "ui_right", "ui_accept", "ui_sword", "ui_dash", "ui_interact"]:
		text = text.replace("{%s}" % action, control_name(action))
	return text

func practice_text() -> String:
	return instruction_text("Kalahkan Aul! {ui_sword}: serang | {ui_dash}: dash | {ui_accept}: lompat")

func refresh_control_text() -> void:
	var interact_key := control_name("ui_interact")
	$NPC/Prompt.text = "[%s] Bicara" % interact_key
	if step == Step.WAITING:
		objective.text = "Bicara dengan %s (%s)." % [npc_name, interact_key]
	elif step == Step.PRACTICE:
		objective.text = practice_text()
	elif step == Step.REPORT:
		objective.text = "Kembali dan lapor kepada %s (%s)." % [npc_name, interact_key]
		$NPC/Prompt.text = "[%s] Lapor" % interact_key
	elif step == Step.REPORT_DIALOGUE:
		body_text.text = report_text
		$TutorialUI/Dialogue/Margin/Content/Next.text = "Selesai [%s]" % interact_key
	elif step == Step.DIALOGUE and page < instructions.size():
		body_text.text = instruction_text(instructions[page])
		var caption := "Mulai latihan" if page == instructions.size() - 1 else "Lanjut"
		$TutorialUI/Dialogue/Margin/Content/Next.text = "%s [%s]" % [caption, interact_key]

func _process(delta: float) -> void:
	if dialogue.visible:
		position_dialogue()
	control_refresh_left -= delta
	if control_refresh_left <= 0.0:
		control_refresh_left = 0.25
		refresh_control_text()

func _npc_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby = true
		$NPC/Prompt.show()

func _npc_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby = false
		$NPC/Prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_interact") and not event.is_echo():
		if step in [Step.DIALOGUE, Step.REPORT_DIALOGUE]:
			advance_dialogue()
		elif nearby:
			interact()
		else:
			return
		get_viewport().set_input_as_handled()

func interact() -> void:
	if step == Step.WAITING:
		step = Step.DIALOGUE
		page = 0
		$GateHint.hide()
		if is_instance_valid(player):
			previous_physics = player.is_physics_processing()
			player.set_physics_process(false)
		dialogue.show()
		$TutorialUI/Dialogue/Margin/Content/Speaker.text = npc_name
		show_page()
	elif step == Step.REPORT:
		step = Step.REPORT_DIALOGUE
		$GateHint.hide()
		if is_instance_valid(player):
			previous_physics = player.is_physics_processing()
			player.set_physics_process(false)
		$TutorialUI/Dialogue/Margin/Content/Speaker.text = npc_name
		dialogue.show()
		refresh_control_text()
		position_dialogue()
	elif step == Step.PRACTICE:
		objective.text = practice_text()
	elif step == Step.COMPLETE:
		objective.text = "%s: Bagus! Silakan menuju gate Room 1." % npc_name

func show_page() -> void:
	if page >= instructions.size():
		begin_practice()
		return
	refresh_control_text()
	position_dialogue()

func position_dialogue() -> void:
	# Convert the NPC head position to screen coordinates so the box follows
	# Semar through camera movement while keeping text at readable UI scale.
	var head: Vector2 = $NPC.get_global_transform_with_canvas() * Vector2(0, -60)
	var viewport_size := get_viewport_rect().size
	dialogue.size.x = minf(620.0, viewport_size.x - 24.0)
	var desired := head - Vector2(dialogue.size.x * 0.5, dialogue.size.y + 12.0)
	dialogue.position = Vector2(
		clampf(desired.x, 12.0, maxf(12.0, viewport_size.x - dialogue.size.x - 12.0)),
		clampf(desired.y, 12.0, maxf(12.0, viewport_size.y - dialogue.size.y - 12.0)))

func advance_dialogue() -> void:
	if step == Step.REPORT_DIALOGUE:
		dialogue.hide()
		if is_instance_valid(player):
			player.set_physics_process(previous_physics)
		step = Step.COMPLETE
		objective.text = "%s: Latihan selesai! Masuk gate menuju Room 1." % npc_name
		return
	if step != Step.DIALOGUE:
		return
	page += 1
	show_page()

func begin_practice() -> void:
	dialogue.hide()
	if is_instance_valid(player):
		player.set_physics_process(previous_physics)
	step = Step.PRACTICE
	objective.text = practice_text()
	# Defer creation because interaction can originate in a physics callback.
	call_deferred("spawn_hostile")

func spawn_hostile() -> void:
	if step != Step.PRACTICE or is_instance_valid(hostile):
		return
	hostile = hostile_scene.instantiate() as Node2D
	hostile.scale = Vector2(0.5, 0.5)
	hostile.position = $HostileSpawn.position
	add_child(hostile)
	hostile.tree_exited.connect(_hostile_defeated, CONNECT_ONE_SHOT)

func _hostile_defeated() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	step = Step.REPORT
	$GateHint.hide()
	refresh_control_text()

func can_exit() -> bool:
	return step == Step.COMPLETE

func show_gate_hint() -> void:
	$GateHint.position = $DoorSpawns/Marker0.position + Vector2(-115, -105)
	$GateHint.text = "Berinteraksi dengan %s terlebih dahulu" % npc_name if step == Step.WAITING else "Selesaikan latihan bersama %s terlebih dahulu" % npc_name
	if step in [Step.REPORT, Step.REPORT_DIALOGUE]:
		$GateHint.text = "Lapor kepada %s terlebih dahulu" % npc_name
	$GateHint.show()

func _exit_tree() -> void:
	if step in [Step.DIALOGUE, Step.REPORT_DIALOGUE] and is_instance_valid(player):
		player.set_physics_process(previous_physics)

