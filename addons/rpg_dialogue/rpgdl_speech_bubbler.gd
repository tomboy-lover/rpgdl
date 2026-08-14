extends Node

class_name RpgdlSpeechBubbler

const RPGDL_SPEECH_BBLR_GROUP = "RpgdlSpeechBubbler"

@export var character : String

@export var enabled : bool = true

@export_enum("BELOW", "ABOVE") var bubble_position : int = 0

@export var bubble_y_offset : int = 0

func _enter_tree() -> void:
	add_to_group(RPGDL_SPEECH_BBLR_GROUP)

func handle_dialogue() -> void:
	pass
