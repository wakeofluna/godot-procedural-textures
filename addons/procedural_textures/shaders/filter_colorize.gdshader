shader_type canvas_item;
render_mode unshaded;

// NAME:Colorize

// samplers
uniform sampler2D input;
// uniforms
uniform vec4 color_0 : source_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
uniform vec4 color_1 : source_color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

// indirection functions (required)
vec2 sample_input(vec2 uv) {
	return texture(input, uv).ra;
}

// process function (required); takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, vec4 p_color_0, vec4 p_color_1) {
	vec2 v_value = sample_input(uv);
	return vec4(mix(p_color_0.rgb, p_color_1.rgb, v_value.x), v_value.y);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, color_0, color_1);
}
