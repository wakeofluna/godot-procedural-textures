@tool
extends ShaderTexture
class_name ProceduralTexture


@export var design: ProceduralTextureDesign:
	set(new_design):
		if design != new_design:
			if design:
				design.changed.disconnect(_on_design_changed)
				design.input_texture_changed.disconnect(_on_input_texture_changed)
				output = ''
			design = new_design
			if design:
				design.changed.connect(_on_design_changed)
				design.input_texture_changed.connect(_on_input_texture_changed)
			_on_design_changed()

@export var output: String:
	set(new_output):
		if not design:
			new_output = ''
		if output != new_output:
			var new_shader: Shader = null
			if not new_output.is_empty():
				var node := design.get_output(new_output)
				if not node:
					new_output = ''
				else:
					new_shader = node.get_output_shader()
			output = new_output
			shader = new_shader
			_on_output_changed()


func _on_design_changed() -> void:
	notify_property_list_changed()
	emit_changed()


func _on_output_changed() -> void:
	if design:
		for x in design.get_input_names():
			var tex = design.get_default_input_texture_for(x)
			set_default_sampler(x, tex)


func _on_input_texture_changed(tex_name: String) -> void:
	var tex = design.get_default_input_texture_for(tex_name)
	set_default_sampler(tex_name, tex)


func _validate_property(property: Dictionary) -> void:
	if property.name == 'shader':
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == 'output':
		var outputs: Array = design.get_output_names() if design else []
		if outputs.is_empty():
			property.usage += PROPERTY_USAGE_READ_ONLY
		else:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ','.join(outputs)
