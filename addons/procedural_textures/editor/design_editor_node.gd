@tool
extends GraphNode
class_name ProceduralTextureDesignEditorNode


var design_node: ProceduralTextureDesignNode
var undo_redo: EditorUndoRedoManager


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
	assert(not design_node.connections.has(to_port), "cannot add connection to port without removing the connection first")
	assert(not detect_circular_reference(from_node), "attempted to create a circular reference")
	design_node.connections[to_port] = { "from_node": from_node, "from_port": from_port }


func detect_circular_reference(to_node: ProceduralTextureDesignNode) -> bool:
	return _detect_circular_reference(to_node, design_node)


static func _detect_circular_reference(current: ProceduralTextureDesignNode, target: ProceduralTextureDesignNode) -> bool:
	if current == target:
		return true
	for x in current.connections:
		if _detect_circular_reference(current.connections[x].from_node, target):
			return true
	return false


func get_connection_to(to_port: int) -> Dictionary:
	var conn = design_node.connections.get(to_port, {})
	if conn.has("from_node") and not conn["from_node"]:
		printerr("Invalid ProceduralTextureDesign connection, likely due to a load error or circular reference")
		design_node.connections.erase(to_port)
		return {}
	return conn


func remove_connection_to(to_port: int) -> void:
	design_node.connections.erase(to_port)


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


func _on_design_property_list_changed() -> void:
	var label: Label

	clear_all_slots()
	for idx in range(get_child_count() -1, -1, -1):
		remove_child(get_child(idx))

	match design_node.get_mode():
		ProceduralTextureDesignNode.Mode.SHADER:
			_build_slots_for_shader(design_node.proc_shader)
		ProceduralTextureDesignNode.Mode.VARIABLE:
			_build_slot_for_value(design_node.output_name, design_node.output_value)
		ProceduralTextureDesignNode.Mode.CONSTANT:
			_build_slot_for_value('Value', design_node.output_value)
		ProceduralTextureDesignNode.Mode.OUTPUT:
			_build_slot_for_output(design_node.output_name)


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

		var cur_value: Variant = design_node._get(uniform.name)
		if uniform.type == TYPE_INT or uniform.type == TYPE_FLOAT:
			var btn = Button.new()
			btn.text = String.num(cur_value, 3)
			design_node.changed.connect(func(): btn.text = String.num(design_node._get(uniform.name), 3))
			var hbox = HBoxContainer.new()
			hbox.add_child(btn)
			hbox.add_child(label)
			add_child(hbox)
		elif uniform.type == TYPE_BOOL:
			var btn = CheckBox.new()
			btn.set_pressed_no_signal(cur_value or false)
			btn.toggled.connect(func(is_on): design_node._set(uniform.name, is_on))
			design_node.changed.connect(func(): btn.set_pressed_no_signal(design_node._get(uniform.name) or false))
			var hbox = HBoxContainer.new()
			hbox.add_child(btn)
			hbox.add_child(label)
			add_child(hbox)
		else:
			add_child(label)

		set_slot_enabled_left(slot_index, true)
		set_slot_color_left(slot_index, get_config_color_for_type(uniform.type))
		set_slot_type_left(slot_index, uniform.type)


func _build_slot_for_value(slot_name: String, slot_value: Variant) -> void:
	var label := Label.new()
	label.text = slot_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	set_slot_enabled_right(0, true)
	set_slot_color_right(0, get_config_color_for_type(typeof(slot_value)))
	set_slot_type_right(0, typeof(slot_value))


func _build_slot_for_output(slot_name: String) -> void:
	var label := Label.new()
	label.text = slot_name.capitalize()
	add_child(label)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, get_config_color_for_type(TYPE_VECTOR4 + 1000))
	set_slot_type_left(0, TYPE_VECTOR4 + 1000)


func _on_position_offset_changed() -> void:
	if design_node.graph_position != position_offset:
		var action_name = 'Move Node ' + name
		undo_redo.create_action(action_name, UndoRedo.MERGE_ENDS)
		undo_redo.add_do_property(design_node, 'graph_position', position_offset)
		undo_redo.add_undo_property(design_node, 'graph_position', design_node.graph_position)
		undo_redo.add_undo_property(self, 'position_offset', design_node.graph_position)
		undo_redo.commit_action()
