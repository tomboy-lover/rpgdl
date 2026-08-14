@tool
extends Resource

class_name RPGDLPortraitMapResource

const ALLOWED_TYPES : PackedStringArray = ["png", "tga"]

func select_folder():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_RESOURCES
	
	dialog.dir_selected.connect(func(path: String):
		for file_name in DirAccess.get_files_at(path):
			if file_name.get_extension() in ALLOWED_TYPES:
				var key = file_name.get_basename().replace(" ", "_").to_lower()
				var value = path.path_join(file_name)
				portraits[key] = load(value)
		
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	Engine.get_main_loop().root.add_child(dialog)
	dialog.popup_centered(Vector2(640, 480))

@export_tool_button("Import Portraits From Folder", 'Folder') var import = select_folder

@export var portraits : Dictionary[String, Texture2D]
