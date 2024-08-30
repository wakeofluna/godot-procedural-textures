@tool
extends RefCounted
class_name ProceduralShader


signal changed


var name: String = ""
var includes: Array = []
var structs: Array = []
var functions: Array = []

var shader: Shader = null:
	set(new_shader):
		if shader != new_shader:
			if shader:
				shader.changed.disconnect(_on_shader_updated)
			shader = new_shader
			if shader:
				shader.changed.connect(_on_shader_updated)
			_on_shader_updated()

var resource_path: String:
	get():
		return shader.resource_path if shader else ""


func _on_shader_updated():
	var shader_data = ShaderParser.parse_shader(shader)

	name = shader_data.get("name", "")
	includes = shader_data.get("includes", [])
	structs = shader_data.get("structs", [])
	functions = shader_data.get("functions", [])
	includes.make_read_only()
	structs.make_read_only()
	functions.make_read_only()

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

	changed.emit()


static func create_from_object(object: Object) -> ProceduralShader:
	if object is Shader:
		return create_from_shader(object as Shader)
	return null


static func create_from_shader(shader: Shader) -> ProceduralShader:
	assert(shader)

	var proc_shader = ProceduralShader.new()
	proc_shader.shader = shader
	return proc_shader
