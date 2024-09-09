shader_type canvas_item;
render_mode unshaded;

// NAME:Invert (scalar)

// samplers
uniform sampler2D input;

// indirection functions (required)
vec2 sample_input(vec2 uv) {
	return texture(input, uv).ra;
}

// process function; takes the current UV followed by all uniforms in order
vec2 process(vec2 uv) {
	vec2 value = sample_input(uv);
	return vec2(1.0 - value.x, value.y);
}

// fragment function; for demo purposes
void fragment() {
	vec2 output = process(UV);
	COLOR = output.xxxy;
}
