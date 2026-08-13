@tool
extends Resource

class_name RPGDLAudioChannelResource

func test_me():
	print("clicked")
	# TODO import all audio failes in popup folder picker

@export_tool_button("Import Audio From Folder", 'Folder') var test = test_me

@export var sound_files : Dictionary[String, AudioStream]
