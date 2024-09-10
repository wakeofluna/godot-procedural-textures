shader_type canvas_item;
render_mode unshaded;

// NAME:Colorize

// samplers
uniform sampler2D input;
// uniforms
uniform vec4 color_0 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).r;
}

// process function (required); takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, vec4 p_color_0, vec4 p_color_1) {
	float v_value = sample_input(uv);
	return mix(p_color_0, p_color_1, v_value);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, color_0, color_1);
}
