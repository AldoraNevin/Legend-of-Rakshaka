extends RefCounted
const LOBBY = [
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Lobby Randomize/lobby theme v2.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Lobby Randomize/lobby theme v3.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Lobby Randomize/Lobby Theme.ogg")
]
const STAGE = [
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Stage randomize/battle phase stage.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Stage randomize/bgm_2.mp3"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Stage randomize/stage bgm 1.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/BGM/Stage randomize/stage bgm 2.ogg")
]
const SLASH = [
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/SFX/slash atas.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/SFX/slash bawah.ogg"),
	preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/SFX/slash samping.ogg")
]
const DASH = preload("res://Assets/Legend of Rakshaka/SFX dan BGM FIX/SFX/dash.ogg")
static var lobby_track: AudioStream
static var stage_track: AudioStream

static func configure_music(player: AudioStreamPlayer, lobby: bool, reuse_lobby := false) -> void:
	player.bus = "Music"
	player.volume_db = -12
	var tracks: Array = LOBBY if lobby else STAGE
	var previous: AudioStream = lobby_track if lobby else stage_track
	var choices := tracks.duplicate()
	if choices.size() > 1:
		choices.erase(previous)
	var selected: AudioStream = previous if lobby and reuse_lobby and previous != null else choices.pick_random()
	if lobby:
		lobby_track = selected
	else:
		stage_track = selected
	player.stream = selected
	player.play()
	if not player.finished.is_connected(_next_track.bind(player, lobby)):
		player.finished.connect(_next_track.bind(player, lobby))

static func _next_track(player: AudioStreamPlayer, lobby: bool) -> void:
	configure_music(player, lobby)
