@tool
extends EditorInspectorPlugin
class_name ProceduralTexturesInspectorPlugin


class DesignPreviewControl extends VBoxContainer:
	var design_node: ProceduralTextureDesignNode

	func _handle_changed() -> void:
		var label: Label = get_child(0)
		var rect: TextureRect = get_child(1)

		var all_connected = design_node.all_required_inputs_are_connected()
		label.visible = not all_connected
		rect.visible = all_connected

		if all_connected and not rect.texture.shader:
			rect.texture.shader = design_node.get_output_shader()

		if rect.texture.shader:
			for input_name in design_node.get_input_texture_names():
				rect.texture.set_shader_parameter(input_name, design_node.get_default_input_texture_for(input_name))


func _can_handle(object: Object) -> bool:
	return object is ShaderTexture or object is ProceduralTextureDesignNode


func _parse_begin(object: Object) -> void:
	var min_size := Vector2(192, 192) * EditorInterface.get_editor_scale()

	if object is ShaderTexture:
		var rect: TextureRect = TextureRect.new()
		rect.custom_minimum_size = min_size
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.texture = object
		add_custom_control(rect)

	if object is ProceduralTextureDesignNode:
		var mode: ProceduralTextureDesignNode.Mode = object.get_mode()
		if mode not in [ProceduralTextureDesignNode.Mode.SHADER, ProceduralTextureDesignNode.Mode.OUTPUT]:
			return

		var label := Label.new()
		label.text = "PREVIEW: not all inputs are connected"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.visible = false

		var rect := TextureRect.new()
		rect.size_flags_horizontal = Control.SIZE_FILL
		rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = ShaderTexture.new()
		rect.visible = false

		var control := DesignPreviewControl.new()
		control.design_node = object
		control.custom_minimum_size = min_size
		control.add_child(label)
		control.add_child(rect)
		add_custom_control(control)

		object.changed.connect(control._handle_changed)
		control._handle_changed()
