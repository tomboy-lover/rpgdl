extends AudioStreamPlayer

class_name RpgdlAudioPlayer

const RPGDL_AUDIO_PLAYER_GROUP = 'RpgdlAudioPlayer'

const RPGDL_AUDIO_PLAYER_CHILDREN = 'RpgdlAudioPlayerChild'

var audio_channels : Dictionary[String, AudioStream]

func _enter_tree() -> void:
	add_to_group(RPGDL_AUDIO_PLAYER_GROUP)

func handle_play_audio(channel: String, audio_stream: AudioStream, fade_time: float = 0) -> void:
	pass

func handle_stop_audio(channel: String, fade_time: float = 0) -> void:
	pass
