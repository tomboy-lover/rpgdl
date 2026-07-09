@tool
extends Window

signal new_file_created(path: String)

@onready var new_file_edit : LineEdit = $%NewFileEdit
@onready var template_option : OptionButton = $%TemplateOption
@onready var path_button : Button = $%PathButton
@onready var new_save_Dialog : FileDialog = $%NewSaveDialog
@onready var template_check : CheckBox = $%TemplateCheck

const RES = "res://"
const EXT = ".rpgdl"
const DEFAULT_NAME = "untitled"


func _reset_window() -> void:
	new_file_edit.text = DEFAULT_NAME + EXT
	new_file_edit.grab_focus()
	new_file_edit.select(0, DEFAULT_NAME.length())
	var folder_icon : Texture2D = EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons")
	path_button.icon = folder_icon

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()



func _on_close_requested() -> void:
	hide()


func _on_about_to_popup() -> void:
	_reset_window()


func _on_path_button_pressed() -> void:
	new_save_Dialog.current_path = new_file_edit.text
	new_save_Dialog.popup_centered_ratio(0.5)


func _on_new_save_dialog_file_selected(path: String) -> void:
	new_file_edit.text = path


func _on_create_button_pressed() -> void:
	# check for template
	var contents = ""
	if template_check.button_pressed:
		# TODO add content for templates
		pass
		
	var file_path : String = new_file_edit.text
	if !file_path.begins_with(RES):
		file_path = RES + file_path
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
	
	# update file scan
	#EditorInterface.get_resource_filesystem().update_file(file_path)
	
	hide()
	
	new_file_created.emit(file_path)


func _on_cancel_button_pressed() -> void:
	hide()


func _on_check_box_pressed() -> void:
	if template_check.button_pressed:
		template_option.disabled = false
	else:
		template_option.disabled = true


func _on_new_file_edit_text_submitted(new_text: String) -> void:
	_on_create_button_pressed()
