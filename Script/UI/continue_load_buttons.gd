extends Control
signal load_requested

func _ready() -> void:
	$ContinueButton.pressed.connect(_continue)
	$LoadButton.pressed.connect(func(): load_requested.emit())
	CheckpointManager.checkpoints_changed.connect(refresh)
	CheckpointManager.load_failed.connect(_failed)
	refresh()

func refresh() -> void:
	$ContinueButton.disabled = CheckpointManager.latest_valid_index() < 0
	$ContinueButton.tooltip_text = "Lanjut dari checkpoint masuk ruangan terakhir." if not $ContinueButton.disabled else "Belum ada checkpoint valid. Masuk level untuk membuat autosave."

func _continue() -> void:
	$Status.text = "Memuat..."
	if CheckpointManager.continue_latest():
		$ContinueButton.disabled = true
		$LoadButton.disabled = true
	else:
		_failed(CheckpointManager.last_error)

func _failed(message: String) -> void:
	$Status.text = message
	$LoadButton.disabled = false
	refresh()
