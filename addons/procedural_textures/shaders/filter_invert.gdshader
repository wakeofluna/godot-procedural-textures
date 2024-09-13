shader_type canvas_item;
render_mode unshaded;

// NAME:Invert

// samplers
uniform sampler2D input;

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv) {
	vec4 value = sample_input(uv);
	return vec4(1.0 - value.rgb, value.a);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV);
}
