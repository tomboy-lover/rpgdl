@tool
extends CodeEdit

const BBCODE_COLOR       = Color("#42ffc2")
const STRING_COLOR       = Color("#ebd3a3")
const FUNCTION_COLOR     = Color("#57b3ff")
const COMMENT_COLOR      = Color("#808080")
const KEYWORD_COLOR      = Color("#ff7085")
const FLOW_COLOR         = Color("#ff8ccc")
const NUMBER_COLOR       = Color("#a1dfb7")
const VARIABLE_COLOR     = Color("#ffb380")
const SYMBOL_COLOR       = Color("#abc9e9")
const DEFAULT_COLOR      = Color("#e0e0e0")

const KEYWORDS = ["namespace", "import", "define", "label", "play", "stop", "emit",]
const FLOW_WORDS = ["menu", "jump", "if", "elif", "else", "end"]


func _ready() -> void:
	# Instantiate and assign our custom internal script highlighter
	var highlighter: CodeHighlighter = RpgdlHighlighter.new()
	#var highlighter: CodeHighlighter = CodeHighlighter.new()
	#
	#highlighter.number_color = NUMBER_COLOR
	#highlighter.symbol_color = SYMBOL_COLOR
	#highlighter.function_color = FUNCTION_COLOR
	#
	#for word in KEYWORDS:
		#highlighter.add_keyword_color(word, KEYWORD_COLOR)
	#for word in FLOW_WORDS:
		#highlighter.add_keyword_color(word, FLOW_COLOR)
	#highlighter.add_keyword_color("fade", FUNCTION_COLOR)
	#
	#highlighter.add_color_region('"', '"', STRING_COLOR)
	#highlighter.add_color_region("#", "", COMMENT_COLOR, true)
	#highlighter.add_color_region("$", " ", VARIABLE_COLOR)
	#highlighter.add_color_region("[", "]", BBCODE_COLOR)
	
	self.syntax_highlighter = highlighter


# =====================================================================
# INNER PARSER CLASS
# Inheriting 'SyntaxHighlighter' allows this logic to execute everywhere
# =====================================================================
class RpgdlHighlighter extends CodeHighlighter:
	
	const STATE_NORMAL = 0
	const STATE_TRIPLE_QUOTE = 1
	
	var word_regex = RegEx.new()
	var string_regex = RegEx.new()
	var string_var_regex = RegEx.new()
	var bbcode_regex = RegEx.new()
	var tag_regex = RegEx.new()
	var num_regex = RegEx.new()
	var sym_regex = RegEx.new()
	var math_var_regex = RegEx.new()
	var comment_regex = RegEx.new()

	func _init() -> void:
		word_regex.compile("\\w+(?=[^#]*#)")
		string_regex.compile("\".*?\"")
		string_var_regex.compile("\\{[^\\}]+\\}")
		bbcode_regex.compile("\\[[^\\]]+\\]")
		tag_regex.compile("<.*?>")
		num_regex.compile("\\b\\d+\\b")
		sym_regex.compile("[-+*/%=<>!:]+")
		math_var_regex.compile("\\$")
		comment_regex.compile("#.*$")

	# Internal hook to bind the parent editor node reference safely
	func setup_editor(editor_node: CodeEdit) -> void:
		pass 

	# This native callback handles line-by-line drawing updates
	func _get_line_syntax_highlighting(line: int) -> Dictionary:
		var color_map = {}
		var text = get_text_edit().get_line(line)
		
		if text.is_empty():
			return color_map
			
		# STEP 2: Implement String Color Regions (Overwrites words inside quotes)
		var string_matches = string_regex.search_all(text)
		for sm in string_matches:
			var s_start = sm.get_start()
			var s_end = sm.get_end()
			
			# Paint the start of the string literal region
			color_map[s_start] = {"color": STRING_COLOR}
			
			var str_var_matches = string_var_regex.search_all(text)
			for vm in str_var_matches:
				if vm. get_start() >= s_start and vm.get_end() <= s_end:
					color_map[vm.get_start()] = {"color": VARIABLE_COLOR}
					color_map[vm.get_end()] = {"color": STRING_COLOR}
			
			# STEP 3: Handle Nested BBCode Regions strictly inside this string boundary
			var bb_matches = bbcode_regex.search_all(text)
			for bm in bb_matches:
				if bm.get_start() >= s_start and bm.get_end() <= s_end:
					color_map[bm.get_start()] = {"color": BBCODE_COLOR}
					color_map[bm.get_end()] = {"color": STRING_COLOR} # Revert back to string yellow
			
			
			# Clean up line formatting immediately after the quote closes
			color_map[s_end] = {"color": Color(1, 1, 1)}	
			
		# STEP 4: Implement Comment Regions (Absolute top-layer override)
		var comment_match = comment_regex.search(text)
		if comment_match:
			# Stamping a color at this index forces the rest of the line to be gray
			color_map[comment_match.get_start()] = {"color": COMMENT_COLOR}

		return color_map
