extends Resource

class_name RPGDLResource

@export var name_space: String = ""

# 1. FILE LINKS
# Links to any other .rpgdl files imported at the top of the script
@export var imports: Array[String] = []

# 2. GLOBAL DEFINITIONS (Your new additions!)
# Stores {"hero": {"name": "Arthur", "portrait_dir": "res://..."}}
@export var characters: Dictionary = {} 

# Stores {"sfx": {"dir": "res://audio/sfx/"}}
@export var audio_channels: Dictionary = {}

# 3. NAVIGATION
# Maps label names to their starting line index (e.g., {"start": 0})
@export var bookmarks: Dictionary = {}

# 4. THE LOGIC
# The compiled, flat array of execution dictionaries
@export var instructions: Array[Dictionary] = []
