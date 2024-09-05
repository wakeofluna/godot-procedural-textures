@tool
extends Resource
class_name ProceduralTextureDesignNode


signal description_changed


@export_storage var shader: Shader:
	set(new_shader):
		if shader != new_shader:
			if proc_shader:
				proc_shader.changed.disconnect(emit_changed)
				proc_shader.property_list_changed.disconnect(notify_property_list_changed)
			proc_shader = ProceduralShader.from_shader(new_shader) if new_shader else null
			if proc_shader:
				proc_shader.changed.connect(emit_changed)
				proc_shader.property_list_changed.connect(notify_property_list_changed)
			shader = new_shader
			emit_changed()

@export_storage var graph_position: Vector2 = Vector2(0,0)

var proc_shader: ProceduralShader
var shader_params: Dictionary


func get_description() -> String:
	return proc_shader.name if proc_shader else '(null)'


func _get_property_list() -> Array[Dictionary]:
	if proc_shader:
		return proc_shader.uniforms
	else:
		return []


func _get(property: StringName) -> Variant:
	if shader_params.has(property):
		return shader_params.get(property)
	else:
		return proc_shader.defaults.get(property) if proc_shader else null


func _set(property: StringName, value: Variant) -> bool:
	if not proc_shader or not proc_shader.defaults.has(property):
		return false

	var old_value = shader_params.get(property)
	if old_value == value:
		return true

	var deflt = proc_shader.defaults.get(property)
	if value == deflt:
		if shader_params.has(property):
			shader_params.erase(property)
	else:
		shader_params[property] = value

	changed.emit()
	return true


func _property_can_revert(property: StringName) -> bool:
	return proc_shader.defaults.has(property) if proc_shader else false


func _property_get_revert(property: StringName) -> Variant:
	return proc_shader.defaults.get(property) if proc_shader else null
