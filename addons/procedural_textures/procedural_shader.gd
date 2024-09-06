@tool
extends RefCounted
class_name ProceduralShader


signal changed


var shader: Shader
var name: String = ""
var includes: Array = []
var structs: Array = []
var functions: Array = []

var inputs: Array[Dictionary]
var uniforms: Array[Dictionary]
var defaults: Dictionary
var output_type: int

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


func _init(shader: Shader) -> void:
	assert(shader, "invalid shader for ProceduralShader")
	assert(not shader.has_meta(meta_key), "use ProceduralShader.from_shader() instead of .new()")

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
	uniforms = []
	output_type = TYPE_VECTOR4
	for uniform in shader.get_shader_uniform_list():
		if uniform.hint == PROPERTY_HINT_RESOURCE_TYPE:
			var input = {}
			input.name = uniform.name
			input.type = TYPE_FLOAT
			inputs.append(input)
		else:
			var deflt = RenderingServer.shader_get_parameter_default(shader_rid, uniform.name)
			defaults[uniform.name] = deflt
			uniforms.append(uniform)

	_determine_input_types()
	_determine_output_type()

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


func _determine_input_types() -> void:
	# Scan all functions for texture(<input>, ...)
	# And then see which channels we use based on the postfix, e.g. ".x"
	for f in functions:
		_determine_input_types_delve(f.definition)


func _determine_input_types_delve(scope: Array) -> void:
	for idx in range(scope.size() - 3):
		var token1 = scope[idx]
		if token1.type == ShaderParser.TOKEN_STRING and token1.token == 'texture':
			var token2 = scope[idx+1]
			if token2.type == ShaderParser.TOKEN_BRACE_OPEN and token2.token == '(':
				var brace_contents: Array = token2.contents
				if not brace_contents.is_empty():
					var front: Dictionary = brace_contents.front()
					if front.type == ShaderParser.TOKEN_STRING:
						var input_name = front.token
						var found_type = TYPE_VECTOR4
						var token3 = scope[idx+2]
						if token3.type == ShaderParser.TOKEN_OPERATOR and token3.token == '.':
							var token4 = scope[idx+3]
							if token4.type == ShaderParser.TOKEN_STRING:
								var suffix = token4.token
								if 'a' in suffix or 'w' in suffix:
									found_type = TYPE_VECTOR4
								elif 'b' in suffix or 'z' in suffix:
									found_type = TYPE_VECTOR3
								elif 'g' in suffix or 'y' in suffix:
									found_type = TYPE_VECTOR2
								elif 'r' in suffix or 'x' in suffix:
									found_type = TYPE_FLOAT
						_set_input_type_of(input_name, found_type)

		if token1.type == ShaderParser.TOKEN_BRACE_OPEN:
			_determine_input_types_delve(token1.contents)


func _set_input_type_of(input_name: String, input_type: int) -> void:
	for inp in inputs:
		if inp.name == input_name:
			inp.type = max(inp.type, input_type)
			return
	assert(inputs.has(input_name), "found texture({0}, ...) call in shader {1} but it is not a uniform".format([input_name, name]))



func _determine_output_type() -> void:
	# Assumption: return value of either
	# - function "process" if it exists
	# - the last function that is not "fragment"

	var return_type: Array = []

	if not functions.is_empty():
		for function in functions:
			if function.name == 'process':
				return_type = function.return_type

		if return_type.is_empty():
			return_type = functions.back().return_type

	assert(not return_type.is_empty(), "no return type found in ProceduralShader")

	var type_string = ShaderParser.reconstruct_string(return_type)
	match type_string:
		'bool':
			output_type = TYPE_BOOL
		'int':
			output_type = TYPE_INT
		'float':
			output_type = TYPE_FLOAT
		'vec2':
			output_type = TYPE_VECTOR2
		'vec3':
			output_type = TYPE_VECTOR3
		'vec4':
			output_type = TYPE_VECTOR4
		_:
			assert('unhandled output type "{0}" in ProceduralShader'.format([type_string]))
