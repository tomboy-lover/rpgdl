@tool
extends EditorPlugin

var import_plugin
var editor_tab : Control
const PLUGIN_NAME = "RpgDL"

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	
	# .rpgdl file importer
	import_plugin = preload("res://addons/rpg_dialogue/rpgdl_importer.gd").new()
	add_import_plugin(import_plugin)
	
	# Editor Custom Tab
	var editor_scene = preload("res://addons/rpg_dialogue/rpgdl_workspace.tscn")
	editor_tab = editor_scene.instantiate()
	_make_visible(false)
	EditorInterface.get_editor_main_screen().add_child(editor_tab)
	


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if editor_tab:
		editor_tab.queue_free()
		
	if import_plugin != null:
		remove_import_plugin(import_plugin)
		import_plugin = null

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("File", "EditorIcons")
	#return EditorInterface.get_editor_theme().get_icon("ShaderDock", "EditorIcons")
	#return EditorInterface.get_editor_theme().get_icon("GodotMonochrome", "EditorIcons")
	#return null

func _make_visible(visible: bool) -> void:
	if editor_tab:
		editor_tab.visible = visible

func _handles(object: Object) -> bool:
	return object is RPGDLResource

func _edit(object: Object) -> void:
	if not object or not object.resource_path:
		return
	
	var file_path: String = object.resource_path
	
	if editor_tab:
		editor_tab._on_open_file_selected(file_path)
	EditorInterface.set_main_screen_editor(PLUGIN_NAME)
