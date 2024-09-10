shader_type canvas_item;
render_mode unshaded;

// NAME:Invert (scalar)

// samplers
uniform sampler2D input;

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).r;
}

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv) {
	float value = sample_input(uv);
	return 1.0 - value;
}

// fragment function; for demo purposes
void fragment() {
	float output = process(UV);
	COLOR = vec4(output, output, output, 1.0);
}
