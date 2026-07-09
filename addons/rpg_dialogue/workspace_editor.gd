@tool
extends CodeEdit

func _ready() -> void:
	var highlighter = CodeHighlighter.new()
	
	# 1. Base Colors
	highlighter.number_color = Color("#a6e22e")   # Green
	highlighter.symbol_color = Color("#f92672")   # Pink (for +, -, =, etc.)
	highlighter.function_color = Color("#66d9ef") # Light Blue
	
	# 2. Control Flow Keywords (Pink)
	var control_keywords = ["label", "jump", "if", "elif", "else"]
	for word in control_keywords:
		highlighter.add_keyword_color(word, Color("#f92672"))
		
	# 3. Structural Keywords (Light Blue)
	var structure_keywords = ["menu", "namespace", "emit"]
	for word in structure_keywords:
		highlighter.add_keyword_color(word, Color("#66d9ef"))
		
	# 4. Color Regions (Strings and Comments)
	# Strings (Yellow): Starts with ", ends with "
	highlighter.add_color_region('"', '"', Color("#e6db74"))
	
	# Comments (Grey): Starts with #, ends at the end of the line (true)
	highlighter.add_color_region("#", "", Color("#75715e"), true)
	
	# Variables (Orange): Starts with $, ends at a space
	highlighter.add_color_region("$", " ", Color("#fd971f"))
	
	# Apply the highlighter to the CodeEdit node
	self.syntax_highlighter = highlighter
