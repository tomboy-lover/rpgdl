extends Node

class_name RpgdlNode

signal dialogue(speaker: String, text: String, emotion: String, portait_path: String, caller: RpgdlNode)

signal choice(chioces: Array[Dictionary], caller: RpgdlNode)

signal event(signal_name: String, args : Array[Variant])

signal play(channel: String, audio_stream: AudioStream, fade_time: float)

signal stop(channel: String, fade_time: float)

signal dialogue_ended

@export var rpgdl_script : RPGDLResource = null

@export var auto_attach_ui : bool = true

@export var auto_attach_audio : bool = true

const RPGDL_NODE_GROUP = "RpgdlNode"

enum _NODE_STATES {READY, BUSY, AWAIT_CHOICE, AWAIT_DIALOGUE, ENDED}

var _current_namespace : String

var _current_state : _NODE_STATES = _NODE_STATES.READY

var _current_choices : Array[Dictionary] = []

var _current_line : int = -1

var _current_label : String

var _last_processed_line : int  = -1

var _loaded_audio : Dictionary[String, RPGDLAudioChannelResource] = {}

var _loaded_characters : Dictionary[String, Variant] = {}

func _enter_tree() -> void:
	add_to_group(RPGDL_NODE_GROUP) # for eaiser use with setting the translation

func _ready() -> void:
	if RpgdlWorld:
		#world_data = RpgdlWorld.world_state
		#connect(event.get_name(), RpgdlWorld.publish_signal)
		event.connect(RpgdlWorld.publish_signal)
	
	if auto_attach_ui:
		var ui : RpgdlDialogueUi = get_tree().get_first_node_in_group(RpgdlDialogueUi.RPGDL_UI_GROUP)
		
		#connect(dialogue_ended.get_name(), ui.handle_dialogue_ended)
		dialogue_ended.connect(ui.handle_dialogue_ended)
		dialogue.connect(ui.handle_dialogue)
		choice.connect(ui.handle_choice)
		

func translate_instruction(line_num: int, current_label: String, instruction: Dictionary) -> Dictionary:
	var trans_inst = instruction
	if instruction['type'] == "dialogue":
		trans_inst = instruction.duplicate_deep()
		var tr_key = "{ns}_{line}_{label}_{character}".format({"label": current_label, 
			"character": str(trans_inst['speaker']).to_upper(), "line": "%02d" % line_num, 
			"ns": _current_namespace})
		var tr_value = tr(tr_key)
		if tr_key != tr_value:
			trans_inst['content'] = tr_value
	elif instruction['type'] == 'menu_hub':
		trans_inst = instruction.duplicate_deep()
		for i in range(trans_inst['choices'].len()):
			var tr_key = "{ns}_{line}_{label}_{cond}".format({"label": current_label, 
				"cond": "CHOICE_%02d" % i, "line": "%02d" % line_num, "ns": _current_namespace})
			var tr_value = tr(tr_key)
			if tr_value != tr_key:
				trans_inst['choices'][i]['text'] = tr_value
			if trans_inst['choices'][i]['alt_text']:
				var tr_key_alt = "{ns}_{line}_{label}_{cond}".format({"label": current_label, 
				"cond": "ALT_CHOICE_%02d" % i, "line": "%02d" % line_num, "ns": _current_namespace})
				var tr_value_alt = tr(tr_key_alt)
				if tr_value_alt != tr_key_alt:
					trans_inst['choices'][i]['alt_text'] = tr_value_alt
				
	return trans_inst

func start_script(start_label : String = "start") -> void:
	if !rpgdl_script:
		push_error("missing rpgdl_script")
		return
	if _current_state != _NODE_STATES.READY:
		push_error("rpgdl_script already started")
	
	if rpgdl_script.name_space == null or rpgdl_script.name_space == '':
		_current_namespace = rpgdl_script.resource_path.get_file().get_basename()
	else:
		_current_namespace = rpgdl_script.name_space
	
	_current_line = rpgdl_script.bookmarks.get(start_label)
	_current_state = _NODE_STATES.BUSY
	_process_instruction(_current_line)
 
func make_chioce(choice : int) -> void:
	if _current_state != _NODE_STATES.AWAIT_CHOICE:
		push_error("rpgdl_script not awaiting choice")
	if choice < 0 or choice >= len(_current_choices):
		push_error("invalid choice")
	_current_state = _NODE_STATES.BUSY
	
	# find the line that coresponds to the choice made
	_current_line = rpgdl_script.bookmarks.get("target")
	_process_instruction(_current_line)

func _interpolate_string(raw_string: String) -> String:
	return raw_string.format(RpgdlWorld.world_state)

func _eval_expression(expr: String) -> Variant:
	var clean_expr = ""
	var in_quotes = false
	var escape_next = false
	
	# 1. Lexer Loop: Read character by character
	for i in range(expr.length()):
		var char = expr[i]
		# Handle escaped characters (like \")
		if escape_next:
			clean_expr += char
			escape_next = false
			continue
		if char == "\\":
			clean_expr += char
			escape_next = true
			continue
		# Toggle quote state
		if char == '"':
			in_quotes = !in_quotes
			clean_expr += char
			continue
		# 2. THE MAGIC: Check for the dollar sign
		if char == "$" and not in_quotes:
			# If it's a variable prefix, skip it (do not add to clean_expr)
			continue
		# Add all other characters normally
		clean_expr += char
		
	# 3. Final cleanup before evaluation
	clean_expr = clean_expr.strip_edges()
	var expression = Expression.new()
	if expression.parse(clean_expr) != OK:
		push_error("invalid expression")
		return null
	var result = expression.execute([], RpgdlWorld) 
	
	if not expression.has_execute_failed():
		return result
	push_error("unable to evaluate expression")
	return null

func _math_operation(variable: String, op: String, expr: String) -> void:
	
	var value : Variant = _eval_expression(expr)
	
	if op == "=":
		RpgdlWorld.world_state[variable] = value
		return
	
	match op:
		"+=":
			RpgdlWorld.world_state[variable] += value
		"-=":
			RpgdlWorld.world_state[variable] -= value
		"*=":
			RpgdlWorld.world_state[variable] *= value
		"/=":
			RpgdlWorld.world_state[variable] /= value
		"%=":
			RpgdlWorld.world_state[variable] %= value
		_:
			push_error("invalid math operator")

func next_dialogue() -> void:
	if _current_state != _NODE_STATES.AWAIT_DIALOGUE:
		push_error("rpgdl_script not awaiting dialogue")
	_current_state = _NODE_STATES.BUSY
	_process_instruction(_current_line + 1)

func _process_instruction(line_num: int) -> void:
	if line_num == _last_processed_line:
		push_error("infinite loop encountered line " + str(line_num))
		return
	_last_processed_line = line_num
	var instruction : Dictionary = rpgdl_script.instructions[line_num]
	instruction = translate_instruction(line_num, _current_label, instruction)
	
	match instruction["type"]:
		"label":
			_current_label = instruction["anchor"]
			_current_line = line_num + 1
		"jump":
			_current_line = rpgdl_script.bookmarks.get(instruction["target"])
		"math":
			_math_operation(instruction['variable'], instruction['op'], instruction['expression'])
			_current_line = line_num + 1
		"dialogue":
			_current_state = _NODE_STATES.AWAIT_DIALOGUE
			# get character
			# interpolate values in text content
			# if speech bubbler for character send direct
			# else emit to the dialogue ui
			return # done processing instructions
			
		"play":
			if instruction['channel'] not in _loaded_audio.keys():
				push_error("undefined audio channel %s" % instruction['channel'])
			elif _loaded_audio.get(instruction['channel'])['sounds'] == null:
				push_error("audio channel %s is not a valid RPGDLAudioChannelResource")
			else:
				var audio_stream = _loaded_audio.get(instruction['channel'])['sounds'].get(instruction['sound'])
				if audio_stream == null:
					push_error("sound %s not found in audio channel %s" % [instruction['sound'], instruction['channel']])
				else:
					play.emit(instruction['channel'], audio_stream, 0.0)
				
			_current_line = line_num + 1
			
		"stop":
			pass
			_current_line = line_num + 1
		"condition_hub":
			var branch_list = instruction['branches']
			_current_line = line_num + 1 # emergency exit to prevent infinite loop
			for branch in branch_list:
				if branch['condition'] == 'else' or _eval_expression(branch['condition']):
					_current_line = rpgdl_script.bookmarks.get(branch['target'])
					break
			
		"menu_hub":
			_current_state = _NODE_STATES.AWAIT_CHOICE
			_current_choices = []
			var chioce_list = instruction['choices']
			for a_choice : Dictionary in chioce_list:
				if a_choice['condition'] != null:
					if _eval_expression(a_choice['condition']):
						_current_choices.append({"text": _interpolate_string(a_choice['text']), 'enabled': true, "target": a_choice['target']})
					else:
						_current_choices.append({"text": _interpolate_string(a_choice['alt_text']), 'enabled': false, "target": a_choice['target']})
				else:
					_current_choices.append({"text": _interpolate_string(a_choice['text']), 'enabled': true, "target": a_choice['target']})
			choice.emit(_current_choices, self)
			return

		"emit":
			event.emit(instruction["signal"], instruction.get("args", []))
			_current_line = line_num + 1
			
		"set_ui":
			pass
		"scroll_mode":
			pass
		"page":
			pass
		"next_panel":
			pass
		"show_panel":
			pass
		"wait":
			return
		"delay":
			pass
		"end":
			dialogue_ended.emit()
			return
		
		_: # wildcard
			_current_line = line_num + 1
	_process_instruction(_current_line)
	
	
