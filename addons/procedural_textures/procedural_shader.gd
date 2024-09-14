@tool
extends RefCounted
class_name ProceduralShader


var shader: Shader
var name: String = ""
var includes: Array = []
var structs: Array = []
var functions: Array = []
var sample_functions: Array = []
var process_function: Dictionary = {}

var inputs: Array[Dictionary]
var uniforms: Array[Dictionary]
var defaults: Dictionary
var output_type: int

var warnings: Array[String] = []

var resource_path: String:
	get():
		return shader.resource_path if shader else ''


const meta_key: StringName = "proc_shader"

static func from_shader(shader: Shader) -> ProceduralShader:
	assert(shader, "invalid shader for ProceduralShader")

	if shader.has_meta(meta_key):
		var proc_shader = shader.get_meta(meta_key).get_ref()
		if proc_shader:
			return proc_shader

	var proc_shader = ProceduralShader.new(shader)
	shader.set_meta(meta_key, weakref(proc_shader))
	return proc_shader


func is_valid() -> bool:
	return warnings.is_empty()


func _init(shader: Shader) -> void:
	assert(shader, "invalid shader for ProceduralShader")
	assert(not shader.has_meta(meta_key), "use ProceduralShader.from_shader() instead of .new()")

	self.shader = shader
	shader.changed.connect(_on_shader_updated)
	_on_shader_updated()


func _on_shader_updated():
	var shader_data = ShaderParser.parse_shader(shader)
	warnings = []

	name = shader_data.get("name", "")
	if name == '':
		warnings.append('No NAME comment found in Shader')

	includes = []
	for x: String in shader_data.get("includes", []):
		if !x.is_absolute_path():
			x = shader.resource_path.get_base_dir().path_join(x)
		includes.append(x.simplify_path())
	includes.make_read_only()

	structs = shader_data.get("structs", [])
	structs.make_read_only()

	functions = []
	sample_functions = []
	process_function = {}
	for f in shader_data.get("functions", []):
		if f.name == 'vertex' or f.name == 'fragment' or f.name == 'light':
			continue
		elif f.name == 'process':
			process_function = f
		elif f.name.begins_with('sample_'):
			sample_functions.append(f)
		else:
			functions.append(f)
	functions.make_read_only()
	sample_functions.make_read_only()
	process_function.make_read_only()

	var shader_rid = shader.get_rid()
	inputs = []
	defaults = {}
	uniforms = []
	output_type = TYPE_VECTOR4
	for uniform in shader.get_shader_uniform_list():
		if uniform.hint == PROPERTY_HINT_RESOURCE_TYPE:
			var input = {}
			input.name = uniform.name
			input.type = TYPE_VECTOR4
			inputs.append(input)
		else:
			var deflt = RenderingServer.shader_get_parameter_default(shader_rid, uniform.name)
			defaults[uniform.name] = deflt
			if uniform.type == TYPE_VECTOR2 and uniform.hint == 0:
				uniform.hint = PROPERTY_HINT_LINK
			uniforms.append(uniform)

	_determine_input_types()
	_determine_output_type()

	inputs.make_read_only()
	defaults.make_read_only()
	uniforms.make_read_only()

	warnings.make_read_only()

	notify_property_list_changed()


func _determine_input_types() -> void:
	var found = []

	for f in sample_functions:
		var input_name = f.name.substr(7)
		var return_type = ShaderParser.reconstruct_string(f.return_type)
		var func_type = map_type_to_variant_type(return_type)

		for inp in inputs:
			if inp.name == input_name:
				found.append(input_name)
				inp.type = func_type

		if not input_name in found:
			warnings.append("Found sample_{0}() function in shader \"{1}\" without matching sampler input".format([input_name, name]))

	for input in inputs:
		if input.name not in found:
			warnings.append("No sample_{0}() indirection function found for sampler2D input".format([input.name]))


func _determine_output_type() -> void:
	if process_function.is_empty():
		warnings.append("No process() function found")
		return

	var return_type = process_function.return_type
	var type_string = ShaderParser.reconstruct_string(return_type)
	output_type = map_type_to_variant_type(type_string)


func map_type_to_variant_type(type_str: String) -> int:
	match type_str:
		'bool': return TYPE_BOOL
		'int': return TYPE_INT
		'float': return TYPE_FLOAT
		'vec2': return TYPE_VECTOR2
		'vec3': return TYPE_VECTOR3
		'vec4': return TYPE_VECTOR4
		_:
			assert('unhandled output type "{0}" in ProceduralShader'.format([type_str]))
			return TYPE_VECTOR4
