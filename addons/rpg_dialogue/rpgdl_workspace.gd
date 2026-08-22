@tool
extends Control

# --- UI References ---
@onready var file_menu: PopupMenu = $%FileMenu
@onready var trans_dialog : Window = $%TranslationDialog
@onready var sidebar_list: ItemList = $%ItemList
@onready var editor: CodeEdit = $%WorkspaceEditor
@onready var open_dialog: FileDialog = $%OpenDialog
@onready var save_dialog: FileDialog = $%SaveDialog
@onready var new_dialog: Window = $%NewDialog
@onready var context_menu : PopupMenu = $%ContextMenu

# --- State Data ---
# Dictionary to hold open files. Key = file_path, Value = file_text
var open_files: Dictionary = {}
var current_file_path: String = ""
var right_clicked_index = -1

var file_icon : Texture2D = EditorInterface.get_editor_theme().get_icon("File", "EditorIcons")

func _ready() -> void:
	_setup_file_menu()
	
	# Connect UI Signals
	editor.text_changed.connect(_on_editor_text_changed)
	
	save_dialog.file_selected.connect(_on_save_file_selected)

func _update_bar_title(filename: String, saved: bool = true) -> void:
	if saved:
		$%FileTitle.text = filename
	else:
		$%FileTitle.text = filename + "(*)"

# --- Menu Setup ---
func _setup_file_menu() -> void:
	
	# new dialogue shortcut
	var new_shortcut : Shortcut = Shortcut.new()
	var new_input : InputEventKey = InputEventKey.new()
	new_input.ctrl_pressed = true
	new_input.keycode = KEY_N
	new_shortcut.events.append(new_input)
	
	# save shortcut
	var save_shortcut : Shortcut = Shortcut.new()
	var save_input : InputEventKey = InputEventKey.new()
	save_input.ctrl_pressed = true
	save_input.keycode = KEY_S
	save_shortcut.events.append(save_input)
	
	# save-as shortcut
	var saveas_shortcut : Shortcut = Shortcut.new()
	var saveas_input : InputEventKey = InputEventKey.new()
	saveas_input.ctrl_pressed = true
	saveas_input.alt_pressed = true
	saveas_input.keycode = KEY_S
	saveas_shortcut.events.append(saveas_input)
	
	# save-all shortcut
	var saveall_shortcut : Shortcut = Shortcut.new()
	var saveall_input : InputEventKey = InputEventKey.new()
	saveall_input.alt_pressed = true
	saveall_input.shift_pressed = true
	saveall_input.keycode = KEY_S
	saveall_shortcut.events.append(saveall_input)
	
	file_menu.clear()
	file_menu.add_item("New Dialogue...", 0)
	file_menu.add_item("Open File...", 1)
	file_menu.add_item("Save", 2)
	file_menu.add_item("Save As...", 3)
	file_menu.add_item("Save All", 4)
	file_menu.set_item_shortcut(0, new_shortcut)
	file_menu.set_item_shortcut(2, save_shortcut)
	file_menu.set_item_shortcut(3, saveas_shortcut)
	file_menu.set_item_shortcut(4, saveall_shortcut)
	
	file_menu.add_separator()
	file_menu.add_item("Close File", 5)
	file_menu.add_item("Close All", 6)
	
	
	file_menu.id_pressed.connect(_on_file_menu_id_pressed)


func _on_file_menu_id_pressed(id: int) -> void:
	match id:
		0: new_dialog.popup_centered()
		1: open_dialog.popup_centered_ratio(0.5)
		2: save_current_file()
		3: save_dialog.popup_centered_ratio(0.5)
		5: close_current_file()


# --- File Operations ---
func create_new_file() -> void:
	save_dialog.popup_centered_ratio(0.5)


func _on_open_file_selected(path: String) -> void:
	if not FileAccess.file_exists(path): return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	
	open_files[path] = {
		"filename": path.get_file(), "saved": true, "path": path, "data": content
	}
	_refresh_sidebar()
	_switch_to_file(path)


func save_current_file() -> void:
	editor.convert_indent()
	if current_file_path == "":
		save_dialog.popup_centered_ratio(0.5)
		return
		#
	var file := FileAccess.open(current_file_path, FileAccess.WRITE)
	file.store_string(editor.text)
	file.close()
	open_files[current_file_path]["saved"] = true
	_update_bar_title(current_file_path.get_file(), open_files[current_file_path]["saved"])

	EditorInterface.get_resource_filesystem().update_file(current_file_path)
	_refresh_sidebar()


func _on_save_file_selected(path: String) -> void:
	current_file_path = path
	
	var content = editor.text
	
	open_files[path] = {
		"filename": path.get_file(), "saved": true, "path": path, "data": content
	}
	
	save_current_file()
	_refresh_sidebar()


func reselect_after_close(index : int = 0) -> void:
	
	if len(open_files) > 0:
		if index < 0:
			index = 0
		_switch_to_file(open_files.keys()[index])
		
	else:
		_update_bar_title("")
		current_file_path = ""
		editor.text = ""
	
	_refresh_sidebar()
	

func close_current_file() -> void:
	
	if current_file_path == "": return
	var up_index = open_files.keys().find(current_file_path) - 1
	open_files.erase(current_file_path)
	
	reselect_after_close(up_index)
	

func close_all_files() -> void:
	for f in open_files.keys():
		open_files.erase(f)
	
	reselect_after_close()

func close_below_files(index: int) -> void:
	if index < len(open_files.keys()) - 1:
		for f in open_files.keys().slice(index + 1):
			open_files.erase(f) 
	
	reselect_after_close(index)

func close_other_file(index : int) -> void:
	var keep = open_files.keys()[index]
	for f in open_files.keys():
		if f != keep:
			open_files.erase(f)
	reselect_after_close()

# --- Workspace Navigation ---
func _refresh_sidebar() -> void:
	
	sidebar_list.clear()
	for path in open_files.keys():
		var file_name = path.get_file()
		if !open_files[path]["saved"]:
			file_name = file_name + "(*)"
		sidebar_list.add_item(file_name)
		sidebar_list.set_item_icon(sidebar_list.get_item_count() - 1, file_icon)
		# Optional: Add an icon or tooltip here
		sidebar_list.set_item_tooltip(sidebar_list.get_item_count() - 1, path)
		
	if current_file_path != "":
		sidebar_list.select(open_files.keys().find(current_file_path))

func _on_sidebar_item_selected(index: int) -> void:
	var file_name = sidebar_list.get_item_text(index)
	# Find the full path that matches this file name
	for path in open_files.keys():
		if path.get_file() == file_name:
			_switch_to_file(path)
			break


func _switch_to_file(path: String) -> void:
	# Save current editor state to cache before switching
	if current_file_path != "" and open_files.has(current_file_path):
		open_files[current_file_path]["data"] = editor.text
		
		
	current_file_path = path
	sidebar_list.deselect_all()
	sidebar_list.select(open_files.keys().find(current_file_path))
	editor.text = open_files[path]["data"]
	_update_bar_title(path.get_file(), open_files[path]["saved"])
	

func _on_editor_text_changed() -> void:
	if current_file_path != "":
		var refresh_flag = open_files[current_file_path]["saved"]
		open_files[current_file_path]["data"] = editor.text
		open_files[current_file_path]["saved"] = false
		_update_bar_title(current_file_path.get_file(), open_files[current_file_path]["saved"])
		if refresh_flag:
			_refresh_sidebar()


func _on_new_dialog_new_file_created(path: String) -> void:
	EditorInterface.get_resource_filesystem().scan()
	_on_open_file_selected(path)
	


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		right_clicked_index = index
		_switch_to_file(open_files.keys()[index])
		_refresh_sidebar()
		context_menu.position = DisplayServer.mouse_get_position()
		context_menu.popup()


func _on_context_menu_index_pressed(index: int) -> void:
	match index:
		0: save_current_file()
		1: save_dialog.popup_centered_ratio(0.5)
		2: close_current_file()
		3: close_other_file(open_files.keys().find(current_file_path))
		4: close_below_files(open_files.keys().find(current_file_path))
		5: close_all_files()


func _on_translate_menu_index_pressed(index: int) -> void:
	match index:
		0: trans_dialog.popup_centered()


func _on_item_list_item_selected(index: int) -> void:
	_switch_to_file(open_files.keys()[index])


func _on_save_dialog_file_selected(path: String) -> void:
	EditorInterface.get_resource_filesystem().scan()
	_on_open_file_selected(path)
