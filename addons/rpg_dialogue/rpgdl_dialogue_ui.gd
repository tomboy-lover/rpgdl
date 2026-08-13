extends Control

class_name RpgdlDialogueUi

@export var freeze_game_on_popup : bool = true

## the number of characters per second appear in the dialogue box
@export_range(1.0 , 100.0) var char_scroll_speed : int = 10.0

@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var next_input_action: StringName = &"ui_accept"

const RPGDL_UI_GROUP = "RpgdlDialogueUi"

func _enter_tree() -> void:
	add_to_group(RPGDL_UI_GROUP)

func _ready() -> void:
	visible = false
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func puase_and_show() -> void:
	get_tree().paused = true
	show()

func hide_and_resume() -> void:
	hide()
	get_tree().paused = false
	

func handle_dialogue(speaker: String, text: String, emotion: String, portait_path: String, caller: RpgdlNode) -> void:
	pass
	

func handle_choice(chioces: Array[Dictionary], caller: RpgdlNode) -> void:
	pass
	
func handle_dialogue_ended() -> void:
	hide_and_resume()
