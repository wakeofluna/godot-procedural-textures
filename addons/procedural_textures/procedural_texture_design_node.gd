@tool
extends Resource
class_name ProceduralTextureDesignNode


enum Mode {
	NONE,
	SHADER,
	CONSTANT,
	VARIABLE,
	OUTPUT,
}

const property_name_variable_name: StringName = 'variable_name'
const property_name_default_value: StringName = 'default_value'
const property_name_constant_value: StringName = 'constant_value'
const property_name_output_name: StringName = 'output_name'


@export_storage var graph_position: Vector2 = Vector2(0,0)
@export_storage var connections: Dictionary = {}

@export_storage var output_value: Variant = null:
	set(new_value):
		if output_value != new_value:
			output_value = new_value
			emit_changed()

@export_storage var output_name: String = '':
	set(new_value):
		if output_name != new_value:
			output_name = new_value
			emit_changed()

@export_storage var is_variable: bool = false:
	set(new_value):
		if is_variable != new_value:
			is_variable = new_value
			emit_changed()

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


var proc_shader: ProceduralShader
var shader_params: Dictionary


func get_mode() -> Mode:
	if proc_shader:
		return Mode.SHADER
	elif typeof(output_value) != TYPE_NIL:
		return Mode.VARIABLE if is_variable else Mode.CONSTANT
	elif not output_name.is_empty():
		return Mode.OUTPUT
	return Mode.NONE


func get_description() -> String:
	match get_mode():
		Mode.SHADER:
			return proc_shader.name
		Mode.VARIABLE:
			return 'Variable'
		Mode.CONSTANT:
			return 'Constant'
		Mode.OUTPUT:
			return 'Output'
		Mode.NONE:
			return 'Route'
	assert(false, 'Unhandled internal mode?!')
	return 'INTERNAL ERROR'


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var prop: Dictionary

	match get_mode():
		Mode.SHADER:
			props = proc_shader.uniforms
		Mode.VARIABLE:
			prop = {}
			prop.name = property_name_variable_name
			prop.type = TYPE_STRING
			props.append(prop)
			prop = {}
			prop.name = property_name_default_value
			prop.type = typeof(output_value)
			props.append(prop)
		Mode.CONSTANT:
			prop = {}
			prop.name = property_name_constant_value
			prop.type = typeof(output_value)
			props.append(prop)
		Mode.OUTPUT:
			prop = {}
			prop.name = property_name_output_name
			prop.type = TYPE_STRING
			props.append(prop)

	return props


func _get(property: StringName) -> Variant:
	if property == property_name_variable_name or property == property_name_output_name:
		return output_name
	if property == property_name_default_value or property == property_name_constant_value:
		return output_value
	if shader_params.has(property):
		return shader_params.get(property)
	if proc_shader:
		return proc_shader.defaults.get(property)
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == property_name_variable_name or property == property_name_output_name:
		output_name = value
		return true
	if property == property_name_default_value or property == property_name_constant_value:
		output_value = value
		return true

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
	if property == property_name_variable_name or property == property_name_output_name:
		return false
	if property == property_name_default_value or property == property_name_constant_value:
		return false
	return proc_shader.defaults.has(property) if proc_shader else false


func _property_get_revert(property: StringName) -> Variant:
	return proc_shader.defaults.get(property) if proc_shader else null
