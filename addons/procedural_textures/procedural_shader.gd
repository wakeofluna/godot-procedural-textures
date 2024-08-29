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


const template: String = 'shader_type canvas_item;

// NAME:xxxx

// samplers
uniform sampler2D input;
// uniforms
uniform vec4 color : source_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;

#include "helper_functions.gdshaderinc"

// helper struct to pack uniforms
struct XxxxDef {
	vec4 color;
	vec2 phi;
	float strength;
};

// make_def function; must have all arguments in same order as uniforms
XxxxDef make_def(vec4 p_color, int p_angle, float p_strength) {
	return XxxxDef(
		p_color, degrees_to_phi(p_angle), p_strength
	);
}

// process function; takes the def struct and the current UV
vec4 process(XxxxDef def, vec2 uv) {
	uv = rotate_uv_phi(uv, def.phi);
	vec4 color_in = texture(input, uv);
	return def.color * color_in;
}

// fragment function; for demo purposes
void fragment() {
	XxxxDef def = make_def(color, angle, strength);
	COLOR = process(def, UV);
}
'


func _on_shader_updated():
	var shader_data = ShaderParser.parse_shader(shader)

	name = shader_data.get("name", "")
	includes = shader_data.get("includes", [])
	structs = shader_data.get("structs", [])
	functions = shader_data.get("functions", [])
	includes.make_read_only()
	structs.make_read_only()
	functions.make_read_only()

	if shader:
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
			print('struct {0} {1};'.format([x.name, x.definition]))
		for x in functions:
			print('{0} {1}{2} {{3}}'.format([x.return_type, x.name, x.parameters, ShaderParser._reconstruct_scope(x.definition, 1, '')]))

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
