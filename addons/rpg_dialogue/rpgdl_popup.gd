extends Node

class_name RpgdlPopup

@export_multiline() var popup_text : String

var _theme : Theme = null

func _enter_tree() -> void:
	pass

func _ready() -> void:
	_theme = get_inherited_theme()

func popup_and_pause() -> void:
	get_tree().paused = true

func hide_and_resume() -> void:
	get_tree().paused = false

func get_inherited_theme() -> Theme:
	var current: Node = self
	
	while current != null:
		if current is Control and current.theme != null:
			return current.theme
		current = current.get_parent()
		
	# Fallback to the project's default theme if no parent has one assigned
	return ThemeDB.get_default_theme() 
