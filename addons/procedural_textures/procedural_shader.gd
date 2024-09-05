@tool
extends RefCounted
class_name ProceduralShader


signal changed


const parameter_prefix: String = "shader_"

var shader: Shader
var name: String = ""
var includes: Array = []
var structs: Array = []
var functions: Array = []

var inputs: Array[String]
var uniforms: Array
var defaults: Dictionary
var params: Dictionary

var resource_path: String:
	get():
		return shader.resource_path if shader else ''


func _init(shader: Shader) -> void:
	assert(shader)
	self.shader = shader
	shader.changed.connect(_on_shader_updated)
	_on_shader_updated()


func _on_shader_updated():
	var shader_data = ShaderParser.parse_shader(shader)

	name = shader_data.get("name", "")
	includes = shader_data.get("includes", [])
	structs = shader_data.get("structs", [])
	functions = shader_data.get("functions", [])
	includes.make_read_only()
	structs.make_read_only()
	functions.make_read_only()

	var shader_rid = shader.get_rid()
	inputs = []
	defaults = {}
	uniforms = shader.get_shader_uniform_list() if shader else []
	for uniform in uniforms:
		if uniform.hint == PROPERTY_HINT_RESOURCE_TYPE:
			inputs.append(uniform.name)
		else:
			var deflt = RenderingServer.shader_get_parameter_default(shader_rid, uniform.name)
			defaults[uniform.name] = deflt
	inputs.make_read_only()
	defaults.make_read_only()
	uniforms.make_read_only()

	if false and shader:
		print('==========================================================')
		print('SHADER: {0}'.format([shader.resource_path]))
		print('shader_type canvas_item;')
		print('// NAME:{0}'.format([name]))
		for x: String in includes:
			if !x.is_absolute_path():
				x = shader.resource_path.get_base_dir().path_join(x)
			x = x.simplify_path()
			print('#include "{0}"'.format([x]))
		for x in structs:
			print('struct {0} {{1}};'.format([x.name, ShaderParser.reconstruct_string(x.definition)]))
		for x in functions:
			print('{0} {1}({2}) {{3}}'.format([ShaderParser.reconstruct_string(x.return_type), x.name, ShaderParser.reconstruct_string(x.parameters), ShaderParser.reconstruct_string(x.definition)]))

	notify_property_list_changed()
	changed.emit()


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []

	if !uniforms.is_empty():
		var group = {}
		group.name = 'Shader Parameters'
		group.class_name = ''
		group.type = TYPE_STRING
		group.hint = PROPERTY_HINT_NONE
		group.hint_string = parameter_prefix
		group.usage = PROPERTY_USAGE_GROUP
		props.append(group)

		for uniform in uniforms:
			var tmp = uniform.duplicate()
			tmp.name = parameter_prefix + tmp.name
			props.append(tmp)

	return props


func _get(property: StringName) -> Variant:
	if not property.begins_with(parameter_prefix):
		return null
	property = property.substr(7)
	if params.has(property):
		return params.get(property)
	else:
		return defaults.get(property)


func _set(property: StringName, value: Variant) -> bool:
	if not property.begins_with(parameter_prefix):
		return false
	property = property.substr(7)
	if not defaults.has(property):
		return false

	var old_value = params.get(property)
	if old_value == value:
		return true

	var deflt = defaults.get(property)
	if value == deflt:
		if params.has(property):
			params.erase(property)
	else:
		params[property] = value

	changed.emit()
	return true


func _property_can_revert(property: StringName) -> bool:
	if not property.begins_with(parameter_prefix):
		return false
	property = property.substr(7)
	return defaults.has(property)


func _property_get_revert(property: StringName) -> Variant:
	if not property.begins_with(parameter_prefix):
		return null
	property = property.substr(7)
	return defaults.get(property)
