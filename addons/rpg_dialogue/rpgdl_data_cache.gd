extends Node

class_name RpgdlDataCache


var world_state : Dictionary = {}

# optimization for instant lookups with RPGDL for expresssion evaluation
# use the object instance of the signalbus/worldstate with the Godot Expression eval
func _get(property: StringName) -> Variant:
	if world_state.has(property):
		return world_state[property]
	return null
