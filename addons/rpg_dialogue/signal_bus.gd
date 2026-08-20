extends Node

signal signal_event(event_name: String, args: Array[Variant])

func publish_signal(signal_name: String, args: Array[Variant]) -> void:
	signal_event.emit(signal_name, args)
