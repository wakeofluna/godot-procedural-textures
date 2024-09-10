shader_type canvas_item;
render_mode unshaded;

// NAME:Invert

// samplers
uniform sampler2D input;

// indirection functions (required)
vec3 sample_input(vec2 uv) {
	return texture(input, uv).rgb;
}

// process function; takes the current UV followed by all uniforms in order
vec3 process(vec2 uv) {
	vec3 value = sample_input(uv);
	return 1.0 - value;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = vec4(process(UV), 1.0);
}
