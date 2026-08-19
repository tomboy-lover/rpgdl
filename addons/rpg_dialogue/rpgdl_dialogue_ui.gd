extends Control

class_name RpgdlDialogueUi

@export var freeze_game_on_popup : bool = true

@export var autoplay: bool = false

@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var next_input_action: StringName = &"ui_accept"

const RPGDL_UI_GROUP = "RpgdlDialogueUi"

func _enter_tree() -> void:
	add_to_group(RPGDL_UI_GROUP)

func _ready() -> void:
	visible = false
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func puase_and_show() -> void:
	if freeze_game_on_popup:
		get_tree().paused = true
	show()

func hide_and_resume() -> void:
	hide()
	get_tree().paused = false
	
func handle_dialogue_started(node: RpgdlNode):
	pass
	
func handle_hide_dialogue() -> void:
	pass

func handle_dialogue(speaker: String, text: String, emotion: String, portrait_res: RPGDLPortraitMapResource, anim_res: SpriteFrames, caller: RpgdlNode) -> void:
	pass

func handle_choice(chioces: Array[Dictionary], caller: RpgdlNode) -> void:
	pass
	
func handle_dialogue_ended() -> void:
	hide_and_resume()
