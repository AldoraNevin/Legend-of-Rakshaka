extends Control
@onready var status: Label = $Panel/Status
var busy := false
var pending_delete := -1

func _ready() -> void:
	$Panel/BackButton.pressed.connect(hide)
	for index in range(3):
		$Panel/Slots.get_child(index).get_node("LoadButton").pressed.connect(_load.bind(index))
		$Panel/Slots.get_child(index).get_node("DeleteButton").pressed.connect(_request_delete.bind(index))
	$DeleteConfirmation.confirmed.connect(_confirm_delete)
	$DeleteConfirmation.canceled.connect(func(): pending_delete = -1)
	CheckpointManager.load_failed.connect(_on_failed)
	CheckpointManager.checkpoints_changed.connect(refresh)
	refresh()
	$Panel/Slots/Checkpoint1/LoadButton.grab_focus()

func refresh() -> void:
	var slots := CheckpointManager.list_checkpoints()
	status.text = "Pilih save untuk melanjutkan. Klik Empty Save untuk progres baru. Progres tersimpan otomatis."
	if not CheckpointManager.storage_error.is_empty():
		status.text = CheckpointManager.storage_error
	for index in range(3):
		var row := $Panel/Slots.get_child(index)
		var button: Button = row.get_node("LoadButton")
		var label: Label = row.get_node("Summary")
		button.disabled = busy or not CheckpointManager.storage_error.is_empty()
		var data: Variant = slots[index]
		var delete_button: Button = row.get_node("DeleteButton")
		delete_button.visible = data != null
		delete_button.disabled = busy or not CheckpointManager.storage_error.is_empty()
		if data == null:
			button.text = "Empty Save"
			label.text = "Save %d — Kosong\nMulai petualangan baru" % (index + 1)
			continue
		button.text = "Load"
		var error := CheckpointManager.checkpoint_error(data)
		if not error.is_empty():
			button.disabled = true
			label.text = "Save %d — Tidak tersedia\n%s" % [index + 1, error]
		else:
			label.text = "Save %d • %s • Gold %d\nArtefak %d • Hostile %d • Upgrade %d\n%s" % [index + 1, data.room_label, int(data.player.coin), data.player.artifacts.size(), data.player.enemies.size(), _upgrade_count(data.player.upgrades), str(data.saved_at).replace("T", "  ")]

func _upgrade_count(upgrades: Dictionary) -> int:
	var total := 0
	for level in upgrades.values():
		total += int(level)
	return total

func _load(index: int) -> void:
	if busy:
		return
	busy = true
	var slots := CheckpointManager.list_checkpoints()
	var success := CheckpointManager.create_slot(index) if slots[index] == null else CheckpointManager.load_checkpoint(index)
	if success:
		refresh()
		status.text = "Memuat save..."
		$Panel/BackButton.disabled = true
	else:
		_on_failed(CheckpointManager.last_error)

func _on_failed(message: String) -> void:
	busy = false
	refresh()
	status.text = message
	$Panel/BackButton.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_cancel") and not busy:
		hide()
		get_viewport().set_input_as_handled()

func _request_delete(index: int) -> void:
	if busy or CheckpointManager.loading:
		return
	pending_delete = index
	$DeleteConfirmation.dialog_text = "Hapus Save %d?\nSeluruh progres pada slot ini akan dihapus." % (index + 1)
	$DeleteConfirmation.popup_centered()
	$DeleteConfirmation.get_cancel_button().grab_focus()

func _confirm_delete() -> void:
	var index := pending_delete
	pending_delete = -1
	if index < 0:
		return
	if CheckpointManager.delete_slot(index):
		refresh()
		status.text = "Save %d dihapus. Slot siap untuk progres baru." % (index + 1)
		$Panel/Slots.get_child(index).get_node("LoadButton").grab_focus()
	else:
		_on_failed(CheckpointManager.last_error)
