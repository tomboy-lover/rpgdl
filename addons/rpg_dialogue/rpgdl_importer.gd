@tool
extends EditorImportPlugin
class_name RPGDLImporter

var _comment_regex : RegEx = RegEx.create_from_string('')

# REGEX
# =====

var _dialogue_regex : RegEx
var _math_regex : RegEx

# =====

func print_error(err_string : String) -> void:
	var err_regex = RegEx.create_from_string('^\\s*(?P<link>res:\\/\\/[^:\\s]+(?::\\d+)?)(?P<end>.*)$')
	var result = err_regex.search(err_string)
	print_rich("[color=orangered]●[/color] [color=salmon][b]ERROR:[/b] [url=%s]%s[/url]%s[/color]" % [result.get_string("link"), result.get_string("link"), result.get_string("end")])

func _get_importer_name() -> String:
	return "rpgdl.parser"

func _get_visible_name() -> String:
	return "RPGDL Dialogue"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["rpgdl"])

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "Resource"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return []

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_import_order() -> int:
	return 0

func _get_priority() -> float:
	return 1.0

## function that strips edges and also strips out trailing comments
func _safe_strip(raw_line: String) -> String:
	var in_quotes = false
	var escape_next = false
	var code_part = ""
	
	for i in range(raw_line.length()):
		var char = raw_line[i]
		
		# Handle escaped characters (like \")
		if escape_next:
			code_part += char
			escape_next = false
			continue
			
		if char == "\\":
			code_part += char
			escape_next = true
			continue
			
		# Toggle quote state
		if char == '"':
			in_quotes = !in_quotes
			code_part += char
			continue
			
		# THE MAGIC: If it's a hash AND we are not in quotes, it's a comment!
		if char == '#' and not in_quotes:
			break # Stop reading the rest of the line
			
		code_part += char
		
	return code_part.strip_edges()

## Handles dialogue lines + $ math operations
## _parse_dialogue(clean_line, [source_file_path, line_number])
func _parse_dialogue(clean_line: String, err_prefix: String) -> Dictionary:
	if clean_line == null:
		push_error(err_prefix + "null line")
		return {}
	elif clean_line.begins_with("$"):
		# parse math operation
		var result = _math_regex.search(clean_line)
		if !result:
			push_error(err_prefix + "invalid math line")
			return {}
		var math_dict = {
			"type": "math",
			"variable": result.get_string("variable"),
			"op": result.get_string("operator"),
			"expression": result.get_string("expression")
		}
		return math_dict
	
	else:
		#print("_parse_dialogue() " + clean_line)
		var result = _dialogue_regex.search(clean_line)
		if !result:
			print_error(err_prefix + "invalid dialogue line")
		else:
			var dialogue_dict : Dictionary = {
				"type": "dialogue", 
				"speaker": result.get_string("speaker"), 
				"emotion": null if result.get_string("emotion").is_empty() else result.get_string("emotion"), 
				"content": result.get_string("content"), 
				"audio": null if result.get_string("audio").is_empty() else result.get_string("audio")
			}
			return dialogue_dict
		
	return {}

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	# A. Open and read the raw text file
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:    
		return FileAccess.get_open_error()
	
	var raw_text : String = file.get_as_text()
	file.close()
	
	# 1. ALWAYS create the resource immediately.
	var parsed_resource : RPGDLResource = RPGDLResource.new()
	var parsed_chars : Dictionary = {}
	var parsed_bookmarks : Dictionary = {}
	var parsed_imports : Array[String] = []
	var parsed_instructions : Array[Dictionary] = []
	var parsed_audio : Dictionary = {}
	var parsed_namespace : String = ""
	# 2. ONLY run the parser and inject data if the file actually has text inside it
	if raw_text.strip_edges() != "":
		
		var line_number : int = 0
		var indentation_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*).*$')
		
		_dialogue_regex = RegEx.create_from_string('^(?P<speaker>\\w+)(?:\\s+(?P<emotion>[\\w\\>]+))?\\s+"(?P<content>.*)"(?:\\s+<(?P<audio>[^>]+)>)?$')
		#_dialogue_regex = RegEx.create_from_string('^(?P<speaker>\\w+)(?:\\s+(?P<emotion>\\w+))?\\s+"(?P<content>.*)"$')
		_math_regex = RegEx.create_from_string("^\\s*\\$\\s*(?P<variable>\\w+)\\s*(?P<operator>[\\+\\-\\*\\/\\%]?=)\\s*(?P<expression>.+)$")

		var lines = raw_text.split("\n")
		var is_in_block_string: bool = false
		var block_buffer: String = ""
		var current_character: String = ""
		var block_start_regex : RegEx = RegEx.create_from_string('^(?P<speaker>\\w+)(?:\\s+(?P<emotion>\\w+))?\\s+"""(?P<content>.*)$')
		
		var is_in_condition_block: bool = false
		var current_conditon_id: int = 0
		var expected_indentation: int = 0
		var active_branch_target: String = "" # e.g., "_branch_01_if"
		var condition_stack: Array[Dictionary] = []
		var if_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*)if\\s+(?P<condition>.+):$')
		var elif_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*)elif\\s+(?P<condition>.+):$')
		var else_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*)else\\s*:$')
		
		var is_in_menu_block: bool = false
		var current_menu_id: int = 0
		var menu_stack: Array[Dictionary]
		var menu_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*)menu\\s*\\:$')
		var menu_option_regex : RegEx = RegEx.create_from_string('^(?P<indentation>\\s*)\\"(?P<text>[^"]+)\\"(?:\\s+if\\s+(?P<condition>[^"]+))?(?:\\s+else\\s+\\"(?P<alt_text>[^"]+)\\")?\\s*:$')
		
		
		var define_regex : RegEx = RegEx.create_from_string('^define\\s+(?P<var_name>\\w+)\\s*=\\s*(?P<class_name>\\w+)\\((?P<args>[^\\)]*)\\)$')
		var namespace_regex : RegEx = RegEx.create_from_string('^namespace\\s+(?P<namespace>\\w+)$')
		var import_regex : RegEx = RegEx.create_from_string('^import\\s+"(?P<file_path>res:\\/\\/[^"]+\\.rpgdl)"$')
		var label_regex : RegEx = RegEx.create_from_string('^label\\s+(?P<label_name>\\w+)\\s*:$')
		var jump_regex : RegEx = RegEx.create_from_string('^jump\\s+(?P<jump_target>\\w+)$')
		var emit_regex : RegEx = RegEx.create_from_string('^emit\\s+(?P<signal>\\w+)(?:\\((?P<args>[^\\)]*)\\))?$')
		var play_regex : RegEx = RegEx.create_from_string('^play\\W+(?P<channel>\\w+)\\W+(?P<sound>\\w+)(?:\\s+fade\\s+(?P<fade_time>[0-9]*\\.?[0-9]+))?$')
		var stop_regex : RegEx = RegEx.create_from_string('^stop\\W+(?P<channel>\\w+)(?:\\s+fade\\s+(?P<fade_time>[0-9]*\\.?[0-9]+))?$')
		var set_ui_regex : RegEx = RegEx.create_from_string('^set_ui\\s+(?P<field>\\w+)\\s*=\\s*"(?P<file_path>res:\\/\\/[^"]+\\.\\w+)"$')
		var scroll_mode_regex : RegEx = RegEx.create_from_string('^scroll_mode\\s+\\"(?P<value>\\w+)\\"$')
		var page_regex : RegEx = RegEx.create_from_string('^page\\s+"(?P<file_path>res:\\/\\/[^"]+\\.\\w+)"$')
		var show_panel_regex : RegEx = RegEx.create_from_string('^show_panel\\s+"(?P<panel_name>[^"]+)"$')
		var delay_regex = RegEx.create_from_string('^delay\\s+(?P<time>[0-9]*\\.?[0-9]+)$')
		
		for raw_line in lines:
			
			var clean_line : String = _safe_strip(raw_line)
			if clean_line.is_empty() or clean_line.begins_with("#"):
				line_number += 1
				continue #empty line or comment line
			#print(clean_line)
			var current_indent : int = len(indentation_regex.search(raw_line).get_string("indentation"))
			line_number += 1
			var error_prefix : String = " %s:%d - " % [source_file, line_number]
			
			
			# ---------------------------------------------------
			# 1. ARE WE CURRENTLY INSIDE A TRIPLE-QUOTE BLOCK?
			# ---------------------------------------------------
			if is_in_block_string:
				if '"""' in clean_line:
					# The block string is closing!
					# Grab any text before the closing quotes
					var final_text : String = clean_line.replace('"""', "").strip_edges()
					if not final_text.is_empty():
						block_buffer += "\n" + final_text
						
					# Package the completed massive string into a dictionary
					parsed_instructions.append({
						"type": "dialogue",
						"character": current_character,
						"text": block_buffer.strip_edges()
					})
					
					# Reset the state so normal parsing can resume
					is_in_block_string = false
					block_buffer = ""
					current_character = ""
				else:
					# We are still inside the block. Just append the raw line!
					# We use the raw 'line' to preserve their intentional line breaks
					if block_buffer == "":
						block_buffer = raw_line 
					else:
						block_buffer += "\n" + raw_line 
				
				# Instantly skip to the next line. Do NOT run standard parsing.
				continue 
			# ---------------------------------------------------
			# 2. DOES THIS LINE OPEN A TRIPLE-QUOTE BLOCK?
			# ---------------------------------------------------
			if '"""' in clean_line:
				is_in_block_string = true
				
				# Extract the character's name before the quotes (e.g., 'hero """')
				var parts : PackedStringArray = clean_line.split('"""')
				current_character = parts[0].strip_edges()
				
				# If they typed text immediately after the opening quotes, save it
				var text_after_quotes : String = parts[1].strip_edges()
				if not text_after_quotes.is_empty():
					block_buffer = text_after_quotes
					
				continue 

			var match_if = if_regex.search(raw_line)
			if is_in_condition_block:
				var indent_match = indentation_regex.search(raw_line)
				var cur_indent = len(indent_match.get_string("indentation"))
				if cur_indent % 4 != 0:
					print_error(error_prefix + "mismatch if block indentation")
				
				var elif_match = elif_regex.search(raw_line)
				var else_match = else_regex.search(raw_line)
				var current_condition = condition_stack.get(0) # stack current menu is always the first element
				if cur_indent <= current_condition.get("indent"):
					var end_anchor = "_branch_%02d_end" % current_condition.get("id")
					parsed_instructions.append({"type": "jump", "target": end_anchor})
					
				if elif_match:
					var expression = elif_match.get_string("condition")
					var elif_label = {"type": "label", "anchor": "_branch_%02d_elif_%02d" % [current_conditon_id, len(current_condition.get("condition_hub").get("branches")) + 1]}
					parsed_instructions.append(elif_label)
					current_condition.get("condition_hub").get("branches").append({"condition": expression, "target": elif_label.get("anchor")})
					continue
					
				elif else_match:
					var else_label = {"type": "label", "anchor": "_branch_%02d_else_%02d" % [current_conditon_id, len(current_condition.get("condition_hub").get("branches")) + 1]}
					parsed_instructions.append(else_label)
					current_condition.get("condition_hub").get("branches").append({"condition": "else", "target": else_label.get("anchor")})
					continue
				
				elif cur_indent <= current_condition.get("indent"):
					var end_condition = condition_stack.pop_front()
					var end_anchor = "_branch_%02d_end" % end_condition.get("id")
					parsed_instructions.append({"type": "label", "anchor": end_anchor})
					
					if len(condition_stack) == 0:
						is_in_condition_block = false
						current_condition = null
					else:
						current_condition = condition_stack.get(0)
				
				elif match_if:
					var new_condition = {"type": "condition_hub", "branches": []}
					var expression = match_if.get_string("condition")
					current_conditon_id += 1
					condition_stack.push_front({"indent": cur_indent, "condition_hub": new_condition, "id": current_conditon_id})
					parsed_instructions.append(new_condition)
					var if_label = {"type": "label", "anchor": "_branch_%02d_if_01" % current_conditon_id}
					parsed_instructions.append(if_label)
					new_condition.get("branches").append({"condition": expression, "target": if_label.get("anchor")})
					continue
				
				else:
					pass # instructions go under current condition branch
			
			elif match_if:
				is_in_condition_block = true
				var indent = len(match_if.get_string("indentation"))
				if indent % 4 != 0:
					print_error(error_prefix + "mismatch if block indentation")
					
				var new_condition = {"type": "condition_hub", "branches": []}
				var expression = match_if.get_string("condition")
				current_conditon_id += 1
				condition_stack.push_front({"indent": indent, "condition_hub": new_condition, "id": current_conditon_id})
				parsed_instructions.append(new_condition)
				var if_label = {"type": "label", "anchor": "_branch_%02d_if_01" % current_conditon_id}
				parsed_instructions.append(if_label)
				new_condition.get("branches").append({"condition": expression, "target": if_label.get("anchor")})
				continue

			var match_menu = menu_regex.search(raw_line)
			if is_in_menu_block:
				var indent_match = indentation_regex.search(raw_line)
				var cur_indent = len(indent_match.get_string("indentation"))
				if cur_indent % 4 != 0:
					print_error(error_prefix + "mismatch menu indentation")
				
				var match_option = menu_option_regex.search(raw_line)
				var current_menu = menu_stack.get(0) # stack current menu is always the first element
				if cur_indent <= current_menu.get("indent"):
					var end_menu = menu_stack.pop_front()
					var end_anchor = "_menu_%02d_end" % end_menu.get("id")
					parsed_instructions.append({"type": "label", "anchor": end_anchor})
					if len(menu_stack) == 0:
						is_in_menu_block = false
						current_menu = null # exiting menu
					else:
						current_menu = menu_stack.get(0) # update current menu
					
				if match_menu:
					var new_menu = {"type": "menu_hub", "choices": []}
					is_in_menu_block = true
					current_menu_id += 1
					menu_stack.push_front({"indent": len(indent_match.get_string("indentation")), "menu_hub": new_menu, "id": current_menu_id})
					parsed_instructions.append(new_menu)
					continue
					
				elif match_option:
					var current_choice_id = len(current_menu.get("menu_hub").get("choices"))
					if current_choice_id > 0:
						parsed_instructions.append({"type": "jump", "target": "_menu_%02d_end" % current_menu.get("id")})
						
					var option_text = match_option.get_string("text")
					var option_alt_text = match_option.get_string(("alt_text"))
					var condition = match_option.get_string("condition")
					current_choice_id = current_choice_id + 1
					var choice = {
						"text": option_text,
						"condition": null if condition.is_empty() else condition,
						"alt_text": null if option_alt_text.is_empty() else option_alt_text,
						"target": "_menu_%02d_choice_%02d" % [current_menu.get("id"), current_choice_id]
					}
					current_menu.get("menu_hub").get("choices").append(choice)
					parsed_instructions.append({"type": "label", "anchor": choice.get("target")})
					continue
					
				else:
					pass # instructions go under current option
					
			elif match_menu:
				is_in_menu_block = true
				var indent = len(match_menu.get_string("indentation"))
				if indent % 4 != 0:
					print_error(error_prefix + "mismatch menu indentation")
					
				var new_menu = {"type": "menu_hub", "choices": []}
				current_menu_id += 1
				menu_stack.push_front({"indent": indent, "menu_hub": new_menu, "id": current_menu_id})
				parsed_instructions.append(new_menu)
				continue

			# ---------------------------------------------------
			# 3. STANDARD PARSING (Single Lines, Commands, etc.)
			# ---------------------------------------------------
			if clean_line.begins_with("define "):
				var result = define_regex.search(clean_line)
				if result:
					var var_name = result.get_string("var_name")
					var def_class = result.get_string("class_name")
					var def_args = safe_split(result.get_string("args"))
					
					match def_class:
						
						"Character":
							# Only 1 argument (the name) is strictly required now
							if len(def_args) < 1:
								push_error(error_prefix + " not enough arguments for Character - requires at least a name")
							else:
								# 1. Set default fallbacks
								var display_name = ""
								var portraits = null
								var show_nametag = true
								var temp_resource = null
								# 2. Dynamically loop through the arguments
								for i in range(def_args.size()):
									var arg = def_args[i].strip_edges()
									# Handle Keyword Arguments (Kwargs)
									if "=" in arg:
										var kwarg_parts = arg.split("=")
										var key = kwarg_parts[0].strip_edges().to_lower()
										var value = kwarg_parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
										
										match key:
											"name":
												display_name = value
											"animations", "anim", "textures", "portraits":
												portraits = value
											"show_name", "show_nametag":
												show_nametag = (value.to_lower() == "true")
									# Handle Positional Arguments
									else:
										var clean_value = arg.trim_prefix('"').trim_suffix('"')
										match i:
											0:
												display_name = clean_value
											1:
												portraits = clean_value
											2:
												show_nametag = (clean_value.to_lower() == "true")
								# 3. Validation
								if display_name == "":
									push_error(error_prefix + " Character requires a name parameter.")
									
								# Only validate the sprite file if the writer actually provided one
								if portraits != null and portraits != "":
									if !portraits.begins_with("res://") or (!portraits.ends_with(".res") and !portraits.ends_with(".tres")):
										print_error(error_prefix + " Character argument %s is not a valid Resource" % portraits)
									elif not ResourceLoader.exists(portraits):
										print_error(error_prefix + " Resource does not exist at path: %s" % portraits)
									else:
										temp_resource = load(portraits)
										if temp_resource is not SpriteFrames and temp_resource is not RPGDLPortraitMapResource:
											print_error(error_prefix + " %s is an invalid resource type. must be either SpriteFrames or RPGDLPortraitMapResource" % portraits)
								
								# 4. Package and Save
								var char_dict = {
									"name": display_name,
									"animations": portraits if temp_resource is SpriteFrames else null,
									"textures": portraits if temp_resource is RPGDLPortraitMapResource else null,
									"show_nametag": show_nametag
								}
									
								parsed_chars[var_name] = char_dict
								
						"Audio":
							if len(def_args) < 1:
								print_error(error_prefix + "not enough arguments for Audio - needs a path for the RPGDLAudioChannelResource")
							else:
								var sounds = null
								var temp_resource = null
								
								# 2. Dynamically loop through the arguments
								for i in range(def_args.size()):
									var arg = def_args[i].strip_edges()
									# Handle Keyword Arguments (Kwargs)
									if "=" in arg:
										var kwarg_parts = arg.split("=")
										var key = kwarg_parts[0].strip_edges().to_lower()
										var value = kwarg_parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
										
										match key:
												"audio", "sounds":
													sounds = value
									# Handle Positional Arguments
									else:
										var clean_value = arg.trim_prefix('"').trim_suffix('"')
										match i:
											0:
												sounds = clean_value
								
								if sounds != null and sounds != "":
									if !sounds.begins_with("res://") or (!sounds.ends_with(".res") and !sounds.ends_with(".tres")):
										print_error(error_prefix + " Audio argument %s is not a valid Resource" % sounds)
									elif not ResourceLoader.exists(sounds):
										print_error(error_prefix + " Resource does not exist at path: %s" % sounds)
									else:
										temp_resource = load(sounds)
										if temp_resource is not RPGDLAudioChannelResource:
											print_error(error_prefix + " %s is an invalid resource type. must be RPGDLAudioChannelResource" % sounds)
											
								var audio_dict = {
									"sounds": sounds if temp_resource is RPGDLAudioChannelResource else null
								}
								parsed_audio[var_name] = audio_dict
				
			elif clean_line.begins_with("import "):
				var result = import_regex.search(clean_line)
				if result:
					parsed_imports.append(result.get_string("file_path"))
				
			elif clean_line.begins_with("namespace "):
				if parsed_namespace == "":
					var result = namespace_regex.search(clean_line)
					parsed_namespace = result.get_string("namespace")
				else:
					print_error(error_prefix + "namespace already defined")
					
			elif clean_line.begins_with("label "):
				var result = label_regex.search(clean_line)
				parsed_instructions.append({"type": "label", "anchor": result.get_string("label_name")})
				
			elif clean_line.begins_with("jump "):
				var result = jump_regex.search(clean_line)
				if result:
					var target = result.get_string("jump_target")
					parsed_instructions.append({"type": "jump", "target": target})
				else:
					print_error(error_prefix + "Invalid jump syntax. Target must be a single word with no spaces.")
				
			elif clean_line.begins_with("emit "):
				var result = emit_regex.search(clean_line)
				parsed_instructions.append({"type": "emit", "signal":result.get_string("signal"), "args": safe_split(result.get_string("args"))})
				
			elif clean_line.begins_with("play "):
				var result = play_regex.search(clean_line)
				if result == null:
					print(clean_line)
				var fade = result.get_string("fade_time")
				parsed_instructions.append({"type": "play", "channel": result.get_string("channel"), "sound": result.get_string("sound"), "fade_time": float(fade) if fade != "" else 0.0})
				
			elif clean_line.begins_with("stop "):
				var result = stop_regex.search(clean_line)
				var fade = result.get_string("fade_time")
				parsed_instructions.append({"type": "stop", "channel": result.get_string("channel"), "fade_time": float(fade) if fade != "" else 0.0 })
				
			elif clean_line.begins_with("set_ui "):
				var result = set_ui_regex.search(clean_line)
				parsed_instructions.append({"type": "set_ui", "field": result.get_string("field"), "file_path": result.get_string("file_path")})
				
			elif clean_line.begins_with("scroll_mode "):
				var result = scroll_mode_regex.search(clean_line)
				parsed_instructions.append({"type": "scroll_mode", "scroll_mode": result.get_string("value")})
				
			elif clean_line.begins_with("page "):
				var result = page_regex.search(clean_line)
				parsed_instructions.append({"type": "page", "path": result.get_string("file_path")})
			
			elif clean_line == "next_panel":
				parsed_instructions.append({"type": "next_panel"})
			
			elif clean_line.begins_with("delay "):
				var result = page_regex.search(delay_regex)
				parsed_instructions.append({"type": "delay", "seconds": float( result.get_string("time"))})
			
			elif clean_line == "wait":
				parsed_instructions.append({"type": "wait"})
				
			elif clean_line == "end":
				parsed_instructions.append({"type": "end"})
				
			elif clean_line == "hide":
				parsed_instructions.append({"type": "hide"})
			
			elif clean_line.begins_with("show_panel "):
				var result = show_panel_regex.search(clean_line)
				parsed_instructions.append({"type": "show_panel", "panel": result.get_string("panel_name")})
			
			else:
				parsed_instructions.append(_parse_dialogue(clean_line, error_prefix))
		
		# parsing ended but still in a menu or a condition
		if is_in_menu_block or is_in_condition_block:
			pass
		
		# throw error forgot to close the block string
		elif is_in_block_string:
			pass
			
		
	# iterate through instructions and add all the bookmarks
	var idx = 0
	for inst :Dictionary in parsed_instructions:
		if inst.get("type") == "label":
			var anchor = inst.get("anchor")
			if parsed_bookmarks.has(anchor):
				push_error("duplicate label %s ...skipping" % [anchor])
			else:
				parsed_bookmarks.set(anchor, idx)
		idx += 1

	# assign values to file

	var filename = save_path + "." + _get_save_extension()
	if !parsed_namespace.is_empty():
		parsed_resource.name_space = parsed_namespace
	parsed_resource.bookmarks = parsed_bookmarks
	parsed_resource.instructions = parsed_instructions
	parsed_resource.imports = parsed_imports
	parsed_resource.characters = parsed_chars
	parsed_resource.audio_channels = parsed_audio
	return ResourceSaver.save(parsed_resource, filename)


# Call this function instead of using string.split(",")
func safe_split(raw_args: String) -> Array:
	var parsed_args = []
	var current_arg = ""
	var in_quotes = false
	var escape_next = false # To handle escaped quotes like \"
	
	for i in range(raw_args.length()):
		var char = raw_args[i]
		
		# If the previous character was a backslash, treat this character as normal text
		if escape_next:
			current_arg += char
			escape_next = false
			continue
			
		# Check for backslash to escape the next character
		if char == "\\":
			current_arg += char
			escape_next = true
			continue
			
		# Toggle the in_quotes flag when we hit a quotation mark
		if char == '"':
			in_quotes = !in_quotes
			current_arg += char
			
		# If we hit a comma, AND we are not inside a string, we finalize the argument!
		elif char == ',' and not in_quotes:
			parsed_args.append(current_arg.strip_edges())
			current_arg = "" # Reset for the next argument
			
		# Otherwise, just add the character to our current argument
		else:
			current_arg += char
			
	# The loop will end without pushing the very last argument, so we do it here:
	if current_arg.strip_edges() != "":
		parsed_args.append(current_arg.strip_edges())
		
	return parsed_args
