@tool
extends Window

@onready var lang_menu : MenuButton = $%LanguageMenu
@onready var default_option : OptionButton = $%DefaultOption
@onready var save_dialog : FileDialog = $%TranslationSaveDialog

var lang_json : Dictionary

func _ready() -> void:
	var f = FileAccess.open("res://addons/rpg_dialogue/languages.json", FileAccess.READ)
	lang_json = JSON.parse_string(f.get_as_text())
	f.close()
	
	for l in lang_json.values():
		lang_menu.get_popup().add_check_item(l)
		default_option.add_item(l)
	if lang_menu.item_count > 0:
		lang_menu.get_popup().set_item_checked(0, true)
		default_option.selected = 0
	lang_menu.get_popup().id_pressed.connect(_on_lang_menu_pressed)

func _on_about_to_popup() -> void:
	
	# scan project for .rpgdl files
	
	pass # Replace with function body.


func _on_close_requested() -> void:
	hide()


func _on_generate_button_pressed() -> void:
	pass # Replace with function body.


func _on_cancel_button_pressed() -> void:
	hide()
	
func _on_lang_menu_pressed(id: int):
	var item_checked: bool = lang_menu.get_popup().is_item_checked(id)
	lang_menu.get_popup().set_item_checked(id, not item_checked)


func _on_translation_save_dialog_file_selected(path: String) -> void:
	pass # Replace with function body.
