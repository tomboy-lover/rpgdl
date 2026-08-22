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

const KEYWORDS = ["namespace", "import", "define", "label", "play", "stop", "emit", "true", "false", "null", "not", "and", "or"]
const FLOW_WORDS = ["menu", "jump", "if", "elif", "else", "end"]
const FUNC_WORDS = ["fade"]
const CONDITON_WORDS = ["if", "elif"]
const FOLLOW_WORDS = ["jump", "play", "stop"]

func _ready() -> void:
	self.syntax_highlighter = RpgdlHighlighter.new()


# =====================================================================
# INNER PARSER CLASS
# Inheriting 'CodeHighlighter' handles multi-context engine targets
# =====================================================================
class RpgdlHighlighter extends CodeHighlighter:
	
	const STATE_NORMAL = 0
	const STATE_TRIPLE_QUOTE = 1
	
	var string_var_regex = RegEx.new()
	var bbcode_regex = RegEx.new()
	var tag_regex = RegEx.new()
	
	var line_states: Dictionary = {}

	func _init() -> void:
		string_var_regex.compile("\\{[^\\}]+\\}")
		bbcode_regex.compile("\\[[^\\]]+\\]")
		tag_regex.compile("<([a-zA-Z_]\\w*):?\\s*([^>]*)>")

	func _get_line_syntax_highlighting(line: int) -> Dictionary:
		var color_map = {}
		var text_edit = get_text_edit()
		var text = text_edit.get_line(line)
		
		var default_text_color = text_edit.get_theme_color("font_color")
		
		var current_state = STATE_NORMAL
		if line > 0 and line_states.has(line - 1):
			current_state = line_states[line - 1]

		if text.is_empty():
			line_states[line] = current_state
			return color_map

		var current_idx = 0
		var line_length = text.length()
		
		var last_keyword_seen = ""
		var in_inline_condition = false
		var emit_paren_depth = 0
		
		# --- INITIAL LINE STRUCTURE SCAN ---
		var line_stripped = text.strip_edges(true, false)
		
		# Persistent Line State Flags
		var is_math_line = line_stripped.begins_with("$")
		var starts_with_special = is_math_line
		
		# Extract the very first word token in the stripped line segment
		var first_word = ""
		if not is_math_line:
			for i in range(line_stripped.length()):
				var c = line_stripped[i]
				if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == "_":
					first_word += c
				else:
					break
			
			if first_word in KEYWORDS or first_word in FLOW_WORDS:
				starts_with_special = true
		
		# Block condition check
		var is_conditional_line = first_word in ["if", "elif"]
		var dynamic_first_word_handled = starts_with_special

		# --- CHARACTER TOKEN SCANNER LOOP ---
		while current_idx < line_length:
			var remaining_text = text.substr(current_idx)
			
			# 1. CRITICAL MULTI-LINE CHECK: Multi-line string block
			if current_state == STATE_TRIPLE_QUOTE:
				color_map[current_idx] = {"color": STRING_COLOR}
				var end_triple_idx = text.find("\"\"\"", current_idx)
				if end_triple_idx != -1:
					_highlight_nested_bbcode(text, current_idx, end_triple_idx + 3, color_map)
					_highlight_nested_str_var(text, current_idx, end_triple_idx + 3, color_map)
					current_idx = end_triple_idx + 3
					color_map[current_idx] = {"color": default_text_color}
					current_state = STATE_NORMAL
					continue
				else:
					_highlight_nested_bbcode(text, current_idx, line_length, color_map)
					_highlight_nested_str_var(text, current_idx, line_length, color_map)
					current_idx = line_length
					break
			
			# 2. Check for Comments
			if remaining_text.begins_with("#"):
				color_map[current_idx] = {"color": COMMENT_COLOR}
				break
				
			# 3. Check for Opening Triple Quotes
			elif remaining_text.begins_with("\"\"\""):
				color_map[current_idx] = {"color": STRING_COLOR}
				var close_triple = text.find("\"\"\"", current_idx + 3)
				if close_triple != -1:
					_highlight_nested_bbcode(text, current_idx, close_triple + 3, color_map)
					_highlight_nested_str_var(text, current_idx, close_triple + 3, color_map)
					current_idx = close_triple + 3
					color_map[current_idx] = {"color": default_text_color}
				else:
					_highlight_nested_bbcode(text, current_idx, line_length, color_map)
					_highlight_nested_str_var(text, current_idx, line_length, color_map)
					current_state = STATE_TRIPLE_QUOTE
					current_idx = line_length
					break
				continue

			# 4. Check for Single-Line Quotes
			elif remaining_text.begins_with("\""):
				in_inline_condition = false
				color_map[current_idx] = {"color": STRING_COLOR}
				var close_single = text.find("\"", current_idx + 1)
				if close_single != -1:
					_highlight_nested_bbcode(text, current_idx, close_single + 1, color_map)
					_highlight_nested_str_var(text, current_idx, close_single + 1, color_map)
					current_idx = close_single + 1
					color_map[current_idx] = {"color": default_text_color}
				else:
					current_idx += 1
				continue

			# 5. Check for Inline Audio / Metadata Tags: <voice: ...>, <sfx: ...>
			elif remaining_text.begins_with("<"):
				var close_angle = text.find(">", current_idx)
				if close_angle != -1:
					_highlight_inline_tags(text, current_idx, close_angle + 1, color_map, default_text_color)
					current_idx = close_angle + 1
					continue

			# 6. Check for Word Tokens (Keywords, Flow, Functions, Variables)
			var first_char = text[current_idx]
			if (first_char >= "a" and first_char <= "z") or (first_char >= "A" and first_char <= "Z") or first_char == "_":
				var word_length = 0
				while current_idx + word_length < line_length:
					var c = text[current_idx + word_length]
					if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") or c == "_":
						word_length += 1
					else:
						break
						
				var word_str = remaining_text.substr(0, word_length)
				
				# Highlight matching
				if word_str in KEYWORDS:
					color_map[current_idx] = {"color": KEYWORD_COLOR}
					color_map[current_idx + word_length] = {"color": default_text_color}
					last_keyword_seen = word_str
				elif word_str in FLOW_WORDS:
					color_map[current_idx] = {"color": FLOW_COLOR}
					color_map[current_idx + word_length] = {"color": default_text_color}
					last_keyword_seen = word_str
					if word_str in ["if", "elif"]:
						in_inline_condition = true
					elif word_str == "else":
						in_inline_condition = false
				elif word_str in FUNC_WORDS:
					color_map[current_idx] = {"color": FUNCTION_COLOR}
					color_map[current_idx + word_length] = {"color": default_text_color}
				else:
					# VARIABLE SELECTION LAYER
					if is_math_line or is_conditional_line or in_inline_condition or (last_keyword_seen == "emit" and emit_paren_depth > 0):
						color_map[current_idx] = {"color": VARIABLE_COLOR}
						color_map[current_idx + word_length] = {"color": default_text_color}
					elif last_keyword_seen == "emit":
						color_map[current_idx] = {"color": FUNCTION_COLOR}
						color_map[current_idx + word_length] = {"color": default_text_color}
					elif not dynamic_first_word_handled:
						color_map[current_idx] = {"color": SYMBOL_COLOR}
						color_map[current_idx + word_length] = {"color": default_text_color}
					elif last_keyword_seen in FOLLOW_WORDS:
						color_map[current_idx] = {"color": SYMBOL_COLOR}
						color_map[current_idx + word_length] = {"color": default_text_color}
						last_keyword_seen = ""
					else:
						var post_word_text = text.substr(current_idx + word_length).strip_edges(true, false)
						if !post_word_text.is_empty() and post_word_text.begins_with("("):
							color_map[current_idx] = {"color": FUNCTION_COLOR}
							color_map[current_idx + word_length] = {"color": default_text_color}
						else:
							color_map[current_idx] = {"color": default_text_color}
					
				dynamic_first_word_handled = true 
				current_idx += word_length
				continue

			# 7. Check for Numeric Digits and Floats (e.g., 50, 50.0, .5)
			var is_digit = first_char >= "0" and first_char <= "9"
			var is_leading_dot_float = first_char == "." and current_idx + 1 < line_length and text[current_idx + 1] >= "0" and text[current_idx + 1] <= "9"
			
			if is_digit or is_leading_dot_float:
				var num_length = 0
				var has_decimal = false
				
				while current_idx + num_length < line_length:
					var c = text[current_idx + num_length]
					if c >= "0" and c <= "9":
						num_length += 1
					elif c == "." and not has_decimal:
						if (num_length > 0) or (current_idx + num_length + 1 < line_length and text[current_idx + num_length + 1] >= "0" and text[current_idx + num_length + 1] <= "9"):
							has_decimal = true
							num_length += 1
						else:
							break
					else:
						break
				
				color_map[current_idx] = {"color": NUMBER_COLOR}
				color_map[current_idx + num_length] = {"color": default_text_color}
				current_idx += num_length
				continue

			# 8. Check for Mathematical Operators, Parentheses & Symbols
			elif first_char in ["$", "-", "+", "*", "/", "%", "=", "<", ">", "!", ":", ",", ".", "(", ")"]:
				if first_char == ":":
					in_inline_condition = false
				elif first_char == "(":
					if last_keyword_seen == "emit":
						emit_paren_depth += 1
				elif first_char == ")":
					if last_keyword_seen == "emit":
						emit_paren_depth = max(0, emit_paren_depth - 1)
						if emit_paren_depth == 0:
							last_keyword_seen = ""
				
				if first_char == "$":
					color_map[current_idx] = {"color": VARIABLE_COLOR}
					color_map[current_idx + 1] = {"color": default_text_color}
				elif first_char == "!" and (is_conditional_line or in_inline_condition):
					if current_idx + 1 < line_length and text[current_idx + 1] == "=":
						color_map[current_idx] = {"color": SYMBOL_COLOR}
						color_map[current_idx + 2] = {"color": default_text_color}
						current_idx += 2
						continue
					else:
						color_map[current_idx] = {"color": KEYWORD_COLOR}
						color_map[current_idx + 1] = {"color": default_text_color}
				else:
					color_map[current_idx] = {"color": SYMBOL_COLOR}
					color_map[current_idx + 1] = {"color": default_text_color}
				
				current_idx += 1
				continue

			current_idx += 1

		line_states[line] = current_state
		return color_map

	func _highlight_inline_tags(text: String, start_pos: int, end_pos: int, color_map: Dictionary, default_text_color: Color) -> void:
		var tag_substr = text.substr(start_pos, end_pos - start_pos)
		var tag_match = tag_regex.search(tag_substr)
		if tag_match:
			color_map[start_pos] = {"color": SYMBOL_COLOR}
			
			var payload = tag_match.get_string(2)
			if not payload.is_empty():
				var payload_start = start_pos + tag_match.get_start(2)
				var payload_end = start_pos + tag_match.get_end(2)
				color_map[payload_start] = {"color": default_text_color}
				color_map[payload_end] = {"color": SYMBOL_COLOR}
				
			color_map[end_pos] = {"color": default_text_color}
		else:
			color_map[start_pos] = {"color": SYMBOL_COLOR}
			color_map[end_pos] = {"color": default_text_color}

	func _highlight_nested_bbcode(text: String, start_limit: int, end_limit: int, color_map: Dictionary) -> void:
		var bb_matches = bbcode_regex.search_all(text)
		for bm in bb_matches:
			if bm.get_start() >= start_limit and bm.get_end() <= end_limit:
				color_map[bm.get_start()] = {"color": BBCODE_COLOR}
				color_map[bm.get_end()] = {"color": STRING_COLOR}

	func _highlight_nested_str_var(text: String, start_limit: int, end_limit: int, color_map: Dictionary) -> void:
		var sv_matches = string_var_regex.search_all(text)
		for sm in sv_matches:
			if sm.get_start() >= start_limit and sm.get_end() <= end_limit:
				color_map[sm.get_start()] = {"color": VARIABLE_COLOR}
				color_map[sm.get_end()] = {"color": STRING_COLOR}
