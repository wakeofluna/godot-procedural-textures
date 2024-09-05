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
	var shader: ProceduralShader = design_node.proc_shader
	var slot_index: int
	var control: Label

	clear_all_slots()
	for idx in range(get_child_count() -1, -1, -1):
		remove_child(get_child(idx))

	for inp in shader.inputs:
		slot_index = get_child_count()
		control = Label.new()
		control.text = inp.name.capitalize()
		add_child(control)
		set_slot_enabled_left(slot_index, true)
		set_slot_color_left(slot_index, get_config_color_for_type(inp.type + 1000))
		set_slot_type_left(slot_index, inp.type + 1000)

	slot_index = get_child_count()
	control = Label.new()
	control.text = 'Output'
	add_child(control)
	set_slot_enabled_right(slot_index, true)
	set_slot_color_right(slot_index, get_config_color_for_type(shader.output_type + 1000))
	set_slot_type_right(slot_index, shader.output_type + 1000)

	add_child(HSeparator.new())

	for uniform in shader.uniforms:
		slot_index = get_child_count()
		control = Label.new()
		control.text = uniform.name.capitalize()
		add_child(control)
		set_slot_enabled_left(slot_index, true)
		set_slot_color_left(slot_index, get_config_color_for_type(uniform.type))
		set_slot_type_left(slot_index, uniform.type)


func _on_position_offset_changed() -> void:
	if design_node.graph_position != position_offset:
		var action_name = 'Move Node ' + name
		undo_redo.create_action(action_name, UndoRedo.MERGE_ENDS)
		undo_redo.add_do_property(design_node, 'graph_position', position_offset)
		undo_redo.add_undo_property(design_node, 'graph_position', design_node.graph_position)
		undo_redo.add_undo_property(self, 'position_offset', design_node.graph_position)
		undo_redo.commit_action()
