extends AudioStreamPlayer

const BATTLE := preload("res://Legend of Rakshaka/BGM/Boss Battle Extended Better.ogg")
const LOOP_START := 20.0
const MIX_DB := -12.0
const FADE := 0.65

func start_battle() -> void:
	var battle := BATTLE.duplicate() as AudioStreamOggVorbis
	battle.loop = true
	battle.loop_offset = LOOP_START
	stream = battle
	bus = "Music"
	volume_db = -60
	play()

var has_looped := false
var previous_time := 0.0

func _process(_delta: float) -> void:
	if not playing:
		return
	var now := get_playback_position()
	if now + 1.0 < previous_time:
		has_looped = true
	previous_time = now
	var since_start := now - LOOP_START if has_looped else now
	var gain := clampf(minf(since_start, stream.get_length() - now) / FADE, 0.004, 1)
	volume_db = MIX_DB + linear_to_db(gain)
