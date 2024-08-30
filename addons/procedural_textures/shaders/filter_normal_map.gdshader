shader_type canvas_item;

// NAME:Normal Map

// samplers
uniform sampler2D input;
// uniforms
uniform float bump_strength : hint_range(0.0, 32.0, 0.1) = 8.0f;

#include "helper_functions.gdshaderinc"

// helper struct to pack uniforms
struct NormalDef {
	float bump_strength;
};

// make_def function; must have all arguments in same order as uniforms
NormalDef make_def(float p_bump_strength) {
	return NormalDef(
		p_bump_strength
	);
}

// process function; takes the def struct and the current UV
vec4 process(NormalDef def, vec2 uv) {
	vec2 uv_offset = uv_per_pixel * 0.5;
	float across_1 = texture(input, uv - vec2(uv_offset.x, 0)).x;
	float across_2 = texture(input, uv + vec2(uv_offset.x, 0)).x;
	float above_1 = texture(input, uv - vec2(0, uv_offset.y)).x;
	float above_2 = texture(input, uv + vec2(0, uv_offset.y)).x;
	
	vec3 up = vec3(0, 1, (above_1 - above_2) * def.bump_strength);
	vec3 across = vec3(1, 0, (across_2 - across_1) * def.bump_strength);
	vec3 normal = cross(across, up);
	normal = normalize(normal);
	
	return vec4(fma(normal, vec3(0.5), vec3(0.5)), 1.0);
}

// fragment function; for demo purposes
void fragment() {
	NormalDef def = make_def(bump_strength);
	COLOR = process(def, UV);
}
