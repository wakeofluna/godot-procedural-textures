@tool
extends GraphNode
class_name ProceduralTextureDesignEditorNode


var design_node: ProceduralTextureDesignNode
var undo_redo: EditorUndoRedoManager
var property_controls: Dictionary = {}


static func get_config_color_for_type(type: int) -> Color:
	var settings = EditorInterface.get_editor_settings()
	var color: Color
	match type % 1000:
		TYPE_BOOL:
			color = settings.get_setting("editors/visual_editors/connection_colors/boolean_color")
		TYPE_INT:
			color = settings.get_setting("editors/visual_editors/connection_colors/scalar_color")
		TYPE_FLOAT:
			color = settings.get_setting("editors/visual_editors/connection_colors/transform_color")
		TYPE_VECTOR2:
			color = settings.get_setting("editors/visual_editors/connection_colors/vector2_color")
		TYPE_VECTOR3:
			color = settings.get_setting("editors/visual_editors/connection_colors/vector3_color")
		TYPE_VECTOR4:
			color = settings.get_setting("editors/visual_editors/connection_colors/vector4_color")
		TYPE_COLOR:
			color = settings.get_setting("editors/visual_editors/connection_colors/sampler_color")
		_:
			assert(false, "unhandled variant type {0} in config colors".format([type % 1000]))
			color = Color.WHITE

	if type >= 1000:
		color = color.lightened(0.5)

	return color


func add_connection_to(to_port: int, from_node: ProceduralTextureDesignNode, from_port: int) -> void:
	design_node.add_connection_to(to_port, from_node, from_port)


func get_connection_to(to_port: int) -> Dictionary:
	return design_node.get_connection_to(to_port)


func remove_connection_to(to_port: int) -> void:
	design_node.remove_connection_to(to_port)


func setup_design_node(undo_redo: EditorUndoRedoManager, design_node: ProceduralTextureDesignNode) -> void:
	assert(design_node, "EditorNode requires a valid DesignNode")
	self.design_node = design_node
	assert(undo_redo)
	self.undo_redo = undo_redo

	title = design_node.get_description()
	position_offset = design_node.graph_position
	position_offset_changed.connect(_on_position_offset_changed)

	design_node.property_list_changed.connect(_on_design_property_list_changed)
	_on_design_property_list_changed()
	design_node.changed.connect(_on_design_changed)
	_on_design_changed()


func _on_design_property_list_changed() -> void:
	clear_all_slots()
	for idx in range(get_child_count() -1, -1, -1):
		remove_child(get_child(idx))

	property_controls = {}

	match design_node.get_mode():
		ProceduralTextureDesignNode.Mode.SHADER:
			_build_slots_for_shader(design_node.proc_shader)
		ProceduralTextureDesignNode.Mode.VARIABLE:
			_build_slot_for_value(true)
		ProceduralTextureDesignNode.Mode.CONSTANT:
			_build_slot_for_value(false)
		ProceduralTextureDesignNode.Mode.INPUT:
			_build_slot_for_input()
		ProceduralTextureDesignNode.Mode.OUTPUT:
			_build_slot_for_output()


func _on_design_changed() -> void:
	title = design_node.get_description()

	for uniform_name in property_controls:
		var value = design_node._get(uniform_name)

		var value_str: String
		if value is String or value is StringName:
			value_str = value
		elif value is int or value is float:
			value_str = String.num(value, 3)
		elif value is Vector2:
			value_str = '(%.3f,%.3f)' % [value.x, value.y]
		elif value is Vector3:
			value_str = '(%.3f,%.3f,%.3f)' % [value.x, value.y, value.z]
		elif value is Vector4:
			value_str = '(%.3f,%.3f,%.3f,%.3f)' % [value.x, value.y, value.z, value.w]
		elif value is Color:
			value_str = '(%d,%d,%d,%d)' % [int(value.r * 255), int(value.g * 255), int(value.b * 255), int(value.a * 255)]
		else:
			value_str = '{0}'.format([value])

		var control = property_controls[uniform_name]
		if control is CheckBox:
			control.set_pressed_no_signal(value as bool)
		elif control is Button:
			if value is Color:
				var tmp: Color = value
				tmp.a = 1.0
				var style := StyleBoxFlat.new()
				style.bg_color = tmp
				control.add_theme_stylebox_override('normal', style)
				style = StyleBoxFlat.new()
				style.bg_color = tmp
				style.border_color = tmp.inverted()
				style.border_width_top = 2
				style.border_width_left = 2
				style.border_width_bottom = 2
				style.border_width_right = 2
				control.add_theme_stylebox_override('hover', style)
			else:
				control.text = value_str
		elif control is Label:
			control.text = value_str
		elif control is TextureRect:
			control.texture = value


func _create_control_for_type(type: int) -> Control:
	if type == TYPE_BOOL:
		var control := CheckBox.new()
		control.disabled = true
		return control
	else:
		var button := Button.new()
		button.custom_minimum_size = Vector2(25, 25)
		return button



func _build_slots_for_shader(shader: ProceduralShader) -> void:
	var slot_index: int
	var label: Label

	for inp in shader.inputs:
		slot_index = get_child_count()
		label = Label.new()
		label.text = inp.name.capitalize()
		add_child(label)
		set_slot_enabled_left(slot_index, true)
		set_slot_color_left(slot_index, get_config_color_for_type(inp.type + 1000))
		set_slot_type_left(slot_index, inp.type + 1000)

	slot_index = get_child_count()
	label = Label.new()
	label.text = 'Output'
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	set_slot_enabled_right(slot_index, true)
	set_slot_color_right(slot_index, get_config_color_for_type(shader.output_type + 1000))
	set_slot_type_right(slot_index, shader.output_type + 1000)

	if not shader.uniforms.is_empty():
		add_child(HSeparator.new())

	for uniform in shader.uniforms:
		slot_index = get_child_count()
		label = Label.new()
		label.text = uniform.name.capitalize()

		var control := _create_control_for_type(uniform.type)
		var hbox = HBoxContainer.new()
		hbox.add_child(control)
		hbox.add_child(label)
		add_child(hbox)
		property_controls[uniform.name] = control

		set_slot_enabled_left(slot_index, true)
		set_slot_color_left(slot_index, get_config_color_for_type(uniform.type))
		set_slot_type_left(slot_index, uniform.type)


func _build_slot_for_value(is_variable: bool) -> void:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var control := _create_control_for_type(typeof(design_node.output_value))
	hbox.add_child(label)
	hbox.add_child(control)
	add_child(hbox)
	set_slot_enabled_right(0, true)
	set_slot_color_right(0, get_config_color_for_type(typeof(design_node.output_value)))
	set_slot_type_right(0, typeof(design_node.output_value))
	if is_variable:
		property_controls[ProceduralTextureDesignNode.property_name_variable_name] = label
		property_controls[ProceduralTextureDesignNode.property_name_default_value] = control
	else:
		label.text = design_node.output_name
		property_controls[ProceduralTextureDesignNode.property_name_constant_value] = control


func _build_slot_for_input() -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	set_slot_enabled_right(0, true)
	set_slot_color_right(0, get_config_color_for_type(TYPE_VECTOR4 + 1000))
	set_slot_type_right(0, TYPE_VECTOR4 + 1000)
	property_controls[ProceduralTextureDesignNode.property_name_output_name] = label

	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(100, 100)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(rect)
	property_controls[ProceduralTextureDesignNode.property_name_input_texture] = rect


func _build_slot_for_output() -> void:
	var label := Label.new()
	add_child(label)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, get_config_color_for_type(TYPE_VECTOR4 + 1000))
	set_slot_type_left(0, TYPE_VECTOR4 + 1000)
	property_controls[ProceduralTextureDesignNode.property_name_output_name] = label


func _on_position_offset_changed() -> void:
	if design_node.graph_position != position_offset:
		var action_name = 'Move Node ' + name
		undo_redo.create_action(action_name, UndoRedo.MERGE_ENDS)
		undo_redo.add_do_property(design_node, 'graph_position', position_offset)
		undo_redo.add_undo_property(design_node, 'graph_position', design_node.graph_position)
		undo_redo.add_undo_property(self, 'position_offset', design_node.graph_position)
		undo_redo.commit_action()
