extends AudioStreamPlayer

class_name RpgdlAudioPlayer

const RPGDL_AUDIO_PLAYER_GROUP = 'RpgdlAudioPlayer'

## value should match the .rpgdl define <channel_name> Audio(...)
@export var rpgdl_channel_name: String

var _track_a: AudioStreamPlayer = null
var _track_b: AudioStreamPlayer = null

func _enter_tree() -> void:
	add_to_group(RPGDL_AUDIO_PLAYER_GROUP)
	
func sync_player_settings() -> void:
	if _track_a:
		_track_a.mix_target = self.mix_target
		_track_a.max_polyphony = self.max_polyphony
		_track_a.bus = self.bus
		_track_a.playback_type = self.playback_type
		_track_a.pitch_scale = self.pitch_scale
	if _track_b:
		_track_b.mix_target = self.mix_target
		_track_b.max_polyphony = self.max_polyphony
		_track_b.bus = self.bus
		_track_b.playback_type = self.playback_type
		_track_b.pitch_scale = self.pitch_scale

func _ready() -> void:
	if rpgdl_channel_name == "" or rpgdl_channel_name == null:
		push_warning("rpgdl_channel_name is unset for %s" % self.name)
	
	_track_a = AudioStreamPlayer.new()
	_track_b = AudioStreamPlayer.new()
	sync_player_settings()
	add_child(_track_a)
	add_child(_track_b)

func handle_play_audio(channel: String, audio_stream: AudioStream, fade_time: float = 0.0) -> void:
	if channel == rpgdl_channel_name:
		crossfade(audio_stream, fade_time)

func handle_stop_audio(channel: String, fade_time: float = 0.0) -> void:
	if channel == rpgdl_channel_name:
		crossfade(null, fade_time)
		
func crossfade(new_stream: AudioStream, fade_time: float) -> void:
	var tmp_track: AudioStreamPlayer = _track_b
	_track_b = _track_a # track_b is the fade out track
	_track_a = tmp_track # tack_a is the fade in track
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(_track_b, "volume_db", -80.0, fade_time)
	tween.chain().tween_callback(_track_b.stop)	
	
	_track_a.stream = new_stream
	if _track_a.stream:
		_track_a.volume_db = -80.0
		_track_a.play()

		tween.parallel().tween_property(_track_a, "volume_db", self.volume_db, fade_time)
