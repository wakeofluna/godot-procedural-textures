shader_type canvas_item;

// NAME:Colorize

// samplers
uniform sampler2D input;
// uniforms
uniform vec4 color_0 : source_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
uniform vec4 color_1 : source_color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

#include "helper_functions.gdshaderinc"

// helper struct to pack uniforms
struct ColorizeDef {
	vec4 color_0;
	vec4 color_1;
};

// make_def function; must have all arguments in same order as uniforms
ColorizeDef make_def(vec4 p_color_0, vec4 p_color_1) {
	return ColorizeDef(
		p_color_0, p_color_1
	);
}

// process function; takes the def struct and the current UV
vec4 process(ColorizeDef def, vec2 uv) {
	float luminance = texture(input, uv).x;
	return mix(def.color_0, def.color_1, luminance);
}

// fragment function; for demo purposes
void fragment() {
	ColorizeDef def = make_def(color_0, color_1);
	COLOR = process(def, UV);
}
