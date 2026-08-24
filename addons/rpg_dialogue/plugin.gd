@tool
extends EditorPlugin

var import_plugin
var editor_tab : Control
const PLUGIN_NAME = "RpgDL"

const SIGNAL_BUS = "SignalBus"
const RPGDL_NODE = "RpgdlNode"
const RPGDL_UI_NODE = "RpgDialogueUI"
const RPGDL_AUDIO_NODE = "RpgdlAudioPlayer"
const RPGDL_BBLR_NODE = "RpgdlSpeechBubbler"
const RPGDL_POPUP_NODE = "RpgdlPopup"
const AUTO_LD_NAME = "RpgdlData"

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	
	load("res://addons/rpg_dialogue/rpgdl_resource.gd")
	load("res://addons/rpg_dialogue/audio_channel_resource.gd")
	
	add_autoload_singleton(AUTO_LD_NAME, "res://addons/rpg_dialogue/rpgdl_data_cache.gd")
	add_autoload_singleton(SIGNAL_BUS, "res://addons/rpg_dialogue/signal_bus.gd")
	
	# .rpgdl file importer
	import_plugin = load("res://addons/rpg_dialogue/rpgdl_importer.gd").new()
	add_import_plugin(import_plugin)
	
	
	# Editor Custom Tab
	var editor_scene = load("res://addons/rpg_dialogue/rpgdl_workspace.tscn")
	editor_tab = editor_scene.instantiate()
	_make_visible(false)
	EditorInterface.get_editor_main_screen().add_child(editor_tab)
	
	# Custom RPGDL Node
	add_custom_type(RPGDL_NODE, "Node", load("res://addons/rpg_dialogue/rpgdl_node.gd"), load("res://icon.svg"))
	add_custom_type(RPGDL_UI_NODE, "Control", load("res://addons/rpg_dialogue/rpgdl_dialogue_ui.gd"), load("res://icon.svg"))
	add_custom_type(RPGDL_BBLR_NODE, "Node", load("res://addons/rpg_dialogue/rpgdl_speech_bubbler.gd"), load("res://icon.svg"))
	add_custom_type(RPGDL_POPUP_NODE, "Node", load("res://addons/rpg_dialogue/rpgdl_popup.gd"), load("res://icon.svg"))
	add_custom_type(RPGDL_AUDIO_NODE, "AudioStreamPlayer", load("res://addons/rpg_dialogue/rpgdl_audio_player.gd"), load("res://icon.svg"))
	


func _exit_tree() -> void:
	
	remove_autoload_singleton(AUTO_LD_NAME)
	remove_autoload_singleton(SIGNAL_BUS)
	
	# custom RPGDL Nodes
	remove_custom_type(RPGDL_UI_NODE)
	remove_custom_type(RPGDL_BBLR_NODE)
	remove_custom_type(RPGDL_POPUP_NODE)
	remove_custom_type(RPGDL_AUDIO_NODE)
	remove_custom_type(RPGDL_NODE)
	
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
