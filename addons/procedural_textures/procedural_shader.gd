@tool
extends Shader
class_name ProceduralShader

@export_placeholder("Name (required)") var name: String


func _init() -> void:
	if code.is_empty():
		code = "shader_type canvas_item;

// uniforms
uniform vec4 color : source_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;
// samplers
uniform sampler2D input;

// helper struct to pack uniforms
struct XxxxDef {
	vec4 color;
	float angle_phi;
	float angle_cos;
	float strength;
};

// definition function; must have all arguments in same order as uniforms with samplers at the end
XxxxDef make_xxxx(vec4 p_color, int p_angle, float p_strength, sampler2D p_input) {
	float rads = radians(float(p_angle));
	return XxxxDef(
		p_color, cos(rads), sin(rads), p_strength
	);
}

// process function; takes the def struct, the current UV, and all samplers in order
vec4 process_xxxx(XxxxDef def, vec2 uv, sampler2D p_input) {
	vec4 color_in = texture(p_input, uv);
	return def.color * color_in;
}

// fragment function; for demo purposes
void fragment() {
	XxxxDef def = make_xxxx(color, angle, strength, input);
	COLOR = process_xxxx(def, UV, input);
}
"


func get_parameter_list(group_name: String = "", group_prefix: String = "shader/") -> Array[Dictionary]:
	var props: Array[Dictionary] = []

	var uniforms: Array = get_shader_uniform_list(false)
	if !uniforms.is_empty():
		if !group_name.is_empty() and !group_prefix.is_empty():
			var group = {}
			group.name = group_name
			group.class_name = ''
			group.type = TYPE_STRING
			group.hint = PROPERTY_HINT_NONE
			group.hint_string = group_prefix
			group.usage = PROPERTY_USAGE_GROUP
			props.append(group)
		else:
			group_prefix = ''

		for uniform in uniforms:
			uniform.parameter_name = uniform.name
			uniform.default = RenderingServer.shader_get_parameter_default(get_rid(), uniform.name)
			uniform.name = group_prefix + uniform.name
			props.append(uniform)

	return props
