extends Node

class_name RpgdlSignalBus

signal rpgdl_event(event_name: String, args: Array[Variant])

var world_state : Dictionary = {}

# optimization for instant lookups with RPGDL for expresssion evaluation
# use the object instance of the signalbus/worldstate with the Godot Expression eval
func _get(property: StringName) -> Variant:
	if world_state.has(property):
		return world_state[property]
	return null

func publish_signal(signal_name: String, args: Array[Variant]) -> void:
	rpgdl_event.emit(signal_name, args)
