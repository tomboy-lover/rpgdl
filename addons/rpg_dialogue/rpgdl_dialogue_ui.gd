extends Control

class_name RpgdlDialogueUi

@export var freeze_game_on_popup : bool = true

@export var autoplay: bool = false

@export var use_default_ui: bool = true

## Text reveal speed in characters per second
@export_range(1, 20.0, 1, "or_greater") var text_speed: float = 10.0

@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var next_input_action: StringName = &"ui_accept"

@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var skip_action: StringName = &"ui_end"

@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var show_hide_ui_action: StringName = &"ui_home"

const RPGDL_UI_GROUP = "RpgdlDialogueUi"

enum UI_STATE {NO_DIALOGUE, SCROLLING, FINISHED}

var _current_dialogue_state: UI_STATE = UI_STATE.NO_DIALOGUE

var _text_reveal_progress: float = 0.0

var _current_rpgdl_node: RpgdlNode

var _choices_parent: Control

var _choices_container: VBoxContainer

var _dialogue_ui_parent: Control

var _dialogue_ui_text: RichTextLabel

var _nametag_ui_parent: Control

var _nametag_ui_label: Label

var _portrait_ui_texture: TextureRect

var _portrait_ui_sprites: AnimatedSprite2D

var _empty_texture : Texture2D = ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))

func _enter_tree() -> void:
	add_to_group(RPGDL_UI_GROUP)

func _ready() -> void:
	var parent = get_parent()
	# Check if the node is at the absolute root or its parent is not a Control node
	if parent == null or not (parent is Control):
		# Set to Full Rect
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
	
	if use_default_ui:
		_setup_default_ui()
		_choices_parent.visible = false
		_nametag_ui_parent.visible = false
		_dialogue_ui_parent.visible = false
	
	#visible = not false
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if use_default_ui:
		if _current_dialogue_state == UI_STATE.SCROLLING:
			if Input.is_action_just_pressed(next_input_action) or Input.is_action_pressed(skip_action):
				_dialogue_ui_text.visible_characters = _dialogue_ui_text.get_total_character_count()
				_current_dialogue_state = UI_STATE.FINISHED
			else:
				_text_reveal_progress += text_speed * delta
				_dialogue_ui_text.visible_characters = int(_text_reveal_progress)
				if _dialogue_ui_text.visible_characters >= _dialogue_ui_text.get_total_character_count():
					_dialogue_ui_text.visible_characters = _dialogue_ui_text.get_total_character_count()
					_current_dialogue_state = UI_STATE.FINISHED
					
		elif _current_dialogue_state == UI_STATE.FINISHED:
			if Input.is_action_just_pressed(next_input_action) or Input.is_action_pressed(skip_action):
				_current_dialogue_state = UI_STATE.NO_DIALOGUE
				_current_rpgdl_node.next_dialogue()

func puase_and_show() -> void:
	if freeze_game_on_popup:
		get_tree().paused = true
	show()

func hide_and_resume() -> void:
	hide()
	get_tree().paused = false
	
func handle_dialogue_started(node: RpgdlNode):
	if use_default_ui:
		_current_rpgdl_node = node
		_choices_parent.visible = false
		_nametag_ui_parent.visible = false
		_dialogue_ui_parent.visible = false
	
func handle_hide_dialogue() -> void:
	print('handle_hide_dialogue')
	if use_default_ui:
		_choices_parent.visible = false
		_nametag_ui_parent.visible = false
		_dialogue_ui_parent.visible = false

func handle_dialogue(speaker: String, text: String, emotion: String, portrait_res: RPGDLPortraitMapResource, anim_res: SpriteFrames, reveal_text: bool, caller: RpgdlNode) -> void:
	if use_default_ui:
		_dialogue_ui_text.text = ""
		_current_rpgdl_node = caller
		if speaker == "" or speaker == null:
			_nametag_ui_label.text = ""
			_nametag_ui_parent.visible = false
		else:
			_nametag_ui_label.text = speaker
			_nametag_ui_parent.visible = true
		_dialogue_ui_text.text = text
		_dialogue_ui_parent.visible = true
		if reveal_text:
			_current_dialogue_state = UI_STATE.SCROLLING
			_text_reveal_progress = 0.0
		else:
			_current_dialogue_state = UI_STATE.FINISHED
			_dialogue_ui_text.visible_characters = _dialogue_ui_text.get_total_character_count()
			_text_reveal_progress = _dialogue_ui_text.get_total_character_count()
			

func handle_choice(chioces: Array[Dictionary], caller: RpgdlNode) -> void:
	if use_default_ui:
		#_current_dialogue_state = UI_STATE.NO_DIALOGUE
		_current_rpgdl_node = caller
		var viewport_size_y = get_viewport().get_visible_rect().size.y
		for c in _choices_container.get_children():
			c.queue_free()
		var first_btn: Button
		var prev_btn: Button
		for choice_idx in range(len(chioces)):
			var choice: Dictionary = chioces[choice_idx]
			var btn = Button.new()
			btn.text = choice['text']
			btn.disabled = choice['disabled']
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 24 if viewport_size_y > 360 else 12)
			btn.pressed.connect(func():
				caller.make_chioce(choice_idx)
				_choices_parent.visible = false
			)
			_choices_container.add_child(btn)
			if choice_idx == 0:
				first_btn = btn
				prev_btn = btn
			else:
				prev_btn.focus_neighbor_bottom = btn.get_path()
				btn.focus_neighbor_top = prev_btn.get_path()
				
		_choices_parent.visible = true
		first_btn.grab_focus()
	
func handle_dialogue_ended() -> void:
	if use_default_ui:
		_choices_parent.visible = false
		_nametag_ui_parent.visible = false
		_dialogue_ui_parent.visible = false
		hide_and_resume()

func _setup_default_ui() -> void:
	var viewport_size_y = get_viewport().get_visible_rect().size.y
	_dialogue_ui_parent = PanelContainer.new()
	var dial_margin = MarginContainer.new()
	var h_split = HSplitContainer.new()
	_portrait_ui_texture = TextureRect.new()
	_portrait_ui_sprites = AnimatedSprite2D.new()
	_dialogue_ui_text = RichTextLabel.new()
	add_child(_dialogue_ui_parent)
	_dialogue_ui_parent.anchor_left = 0.1
	_dialogue_ui_parent.anchor_top = 0.71
	_dialogue_ui_parent.anchor_right = 0.9
	_dialogue_ui_parent.anchor_bottom = 1.0
	_dialogue_ui_parent.offset_left = 0
	_dialogue_ui_parent.offset_top = 0
	_dialogue_ui_parent.offset_right = 0
	_dialogue_ui_parent.offset_bottom = 0
	_dialogue_ui_parent.add_child(dial_margin)
	var dial_margin_size = min(_dialogue_ui_parent.size.y, _dialogue_ui_parent.size.x) / 26
	dial_margin.add_theme_constant_override("margin_left", dial_margin_size)
	dial_margin.add_theme_constant_override("margin_right", dial_margin_size * 2)
	dial_margin.add_theme_constant_override("margin_top", dial_margin_size)
	dial_margin.add_theme_constant_override("margin_bottom", dial_margin_size)
	dial_margin.add_child(h_split)
	h_split.add_child(_portrait_ui_texture)
	h_split.add_child(_dialogue_ui_text)
	h_split.dragging_enabled = false
	h_split.add_theme_constant_override("separation", dial_margin_size * 4)
	h_split.add_theme_constant_override("minimum_grab_thickness", dial_margin_size * 4)
	_dialogue_ui_text.size_flags_horizontal = Control.SIZE_FILL
	_dialogue_ui_text.bbcode_enabled = true
	_dialogue_ui_text.text = "hello there."
	_dialogue_ui_text.add_theme_font_size_override("normal_font_size", 24 if viewport_size_y > 360 else 12)
	_portrait_ui_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_portrait_ui_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait_ui_texture.texture = _empty_texture
	_dialogue_ui_parent.add_child(_portrait_ui_sprites)
	(func(): 
		_portrait_ui_sprites.position = _portrait_ui_texture.position + (_portrait_ui_texture.size / 2) + Vector2(dial_margin_size, dial_margin_size).round()
	).call_deferred()
	_portrait_ui_sprites.position = _portrait_ui_texture.position + _portrait_ui_texture.size
	
	
	_nametag_ui_parent = PanelContainer.new()
	add_child(_nametag_ui_parent)
	_nametag_ui_parent.anchor_left = 0.1
	_nametag_ui_parent.anchor_top = 0.61 #0.56
	_nametag_ui_parent.anchor_right = 0.25
	_nametag_ui_parent.anchor_bottom = 0.71 #0.66
	_nametag_ui_parent.offset_left = 0
	_nametag_ui_parent.offset_top = 0
	_nametag_ui_parent.offset_right = 0
	_nametag_ui_parent.offset_bottom = 0
	_nametag_ui_parent.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var name_margin: MarginContainer = MarginContainer.new()
	_nametag_ui_parent.add_child(name_margin)
	_nametag_ui_label = Label.new()
	name_margin.add_child(_nametag_ui_label)
	_nametag_ui_label.size_flags_vertical = Control.SIZE_FILL
	_nametag_ui_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_nametag_ui_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nametag_ui_label.text = "Jerimiah IV"
	# adjust margins after content is added
	var name_margin_size = min(_nametag_ui_parent.size.y, _nametag_ui_parent.size.x) / 2
	name_margin.add_theme_constant_override("margin_left", name_margin_size)
	name_margin.add_theme_constant_override("margin_right", name_margin_size)
	_nametag_ui_label.add_theme_font_size_override("font_size", 28 if viewport_size_y > 360 else 16)
	
	_choices_parent = PanelContainer.new()
	_choices_container = VBoxContainer.new()
	var choices_margin = MarginContainer.new()
	add_child(_choices_parent)
	_choices_parent.add_child(choices_margin)
	choices_margin.add_child(_choices_container)
	_choices_parent.anchor_left = 0.8 #0.79
	_choices_parent.anchor_top = 0.56 #0.51 #0.34
	_choices_parent.anchor_right = 1.0 #0.99
	_choices_parent.anchor_bottom = 0.66 #0.61 #0.54
	_choices_parent.offset_left = 0
	_choices_parent.offset_top = 0
	_choices_parent.offset_right = 0
	_choices_parent.offset_bottom = 0
	_choices_parent.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices_parent.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choices_container.alignment = BoxContainer.ALIGNMENT_END
	var choices_margin_size = min(_choices_parent.size.x, _choices_parent.size.y) / 20
	choices_margin.add_theme_constant_override("margin_left", choices_margin_size)
	choices_margin.add_theme_constant_override("margin_right", choices_margin_size)
	choices_margin.add_theme_constant_override("margin_top", choices_margin_size)
	choices_margin.add_theme_constant_override("margin_bottom", choices_margin_size)
