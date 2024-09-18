@tool
extends EditorInspectorPlugin
class_name ProceduralTexturesInspectorPlugin


const export_image_sizes: PackedStringArray = [
	"256 x 256",
	"512 x 512",
	"1024 x 1024",
	"2048 x 2048",
	"4096 x 4096",
]
const export_image_size_vectors: PackedVector2Array = [
	Vector2i(256, 256),
	Vector2i(512, 512),
	Vector2i(1024, 1024),
	Vector2i(2048, 2048),
	Vector2i(4096, 4096),
]


class DesignPreviewControl extends VBoxContainer:
	var design_node: ProceduralTextureDesignNode
	var label: Label
	var rect: TextureRect
	var export_as_shader: Button
	var export_as_image: Button
	var dialog_shader: FileDialog = null
	var dialog_image: FileDialog = null

	func init_for(node: ProceduralTextureDesignNode) -> void:
		label = Label.new()
		label.text = "PREVIEW: not all inputs are connected"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.visible = false

		rect = TextureRect.new()
		rect.size_flags_horizontal = Control.SIZE_FILL
		rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = ShaderTexture.new()
		rect.visible = false

		export_as_shader = Button.new()
		export_as_shader.text = 'Export as Shader'
		export_as_shader.disabled = true
		export_as_shader.pressed.connect(_handle_export_as_shader)

		export_as_image = Button.new()
		export_as_image.text = 'Export as Image'
		export_as_image.disabled = true
		export_as_image.pressed.connect(_handle_export_as_image)

		design_node = node
		add_child(label)
		add_child(rect)
		add_child(export_as_shader)
		add_child(export_as_image)

		node.changed.connect(_handle_changed)
		_handle_changed()

	func _handle_changed() -> void:
		var all_connected = design_node.all_required_inputs_are_connected()
		label.visible = not all_connected
		rect.visible = all_connected
		export_as_image.disabled = not all_connected
		export_as_shader.disabled = not all_connected

		if all_connected and not rect.texture.shader:
			rect.texture.shader = design_node.get_output_shader()

		if rect.texture.shader:
			for input_name in design_node.get_input_texture_names():
				rect.texture.set_shader_parameter(input_name, design_node.get_default_input_texture_for(input_name))

	func _handle_export_as_shader() -> void:
		if not dialog_shader:
			dialog_shader = FileDialog.new()
			dialog_shader.exclusive = true
			dialog_shader.access = FileDialog.ACCESS_RESOURCES
			dialog_shader.add_filter('*.gdshader', 'Shaders')
			dialog_shader.confirmed.connect(_handle_save_as_shader)
			add_child(dialog_shader)

		var path = design_node.export_shader_path
		if path.is_empty():
			path = design_node.get_default_shader_export_path()
		dialog_shader.current_path = path
		dialog_shader.popup_centered(Vector2i(600, 600))

	func _handle_save_as_shader() -> void:
		var path: String = dialog_shader.current_path
		design_node.export_shader_path = path
		var shader: Shader = rect.texture.shader
		if shader:
			var err := ResourceSaver.save(shader, path, ResourceSaver.FLAG_NONE)
			if err != OK:
				push_error("Error saving Shader with code: ", error_string(err))
		else:
			push_warning("Failed to generate Shader")
		dialog_shader.hide()

	func _handle_export_as_image() -> void:
		if not dialog_image:
			dialog_image = FileDialog.new()
			dialog_image.exclusive = true
			dialog_image.access = FileDialog.ACCESS_RESOURCES
			dialog_image.add_filter('*.png', 'Images')
			dialog_image.add_option('Export Image Size', export_image_sizes, 1)
			dialog_image.confirmed.connect(_handle_save_as_image)
			add_child(dialog_image)

		var path = design_node.export_image_path
		if path.is_empty():
			path = design_node.get_default_image_export_path()
		dialog_image.current_path = path
		dialog_image.set_option_default(0, design_node.export_image_size_index)
		dialog_image.popup_centered(Vector2i(600, 600))

	func _handle_save_as_image() -> void:
		var path: String = dialog_image.current_path
		var option: int = dialog_image.get_selected_options()[dialog_image.get_option_name(0)]
		design_node.export_image_path = path
		design_node.export_image_size_index = option
		var img: Image = await rect.texture._generate_image(export_image_size_vectors[option])
		if img:
			var err := img.save_png(path)
			if err != OK:
				push_error("Error saving Image with code: ", error_string(err))
			else:
				EditorInterface.get_resource_filesystem().scan()
		else:
			push_warning("Failed to generate texture image")
		dialog_image.hide()


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

		var control := DesignPreviewControl.new()
		control.custom_minimum_size = min_size
		control.init_for(object)
		add_custom_control(control)
