shader_type canvas_item;
render_mode unshaded;

// NAME:Alpha Set (scalar)

// samplers
uniform sampler2D input;
uniform sampler2D alpha_mask;

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).r;
}
float sample_alpha_mask(vec2 uv) {
	return texture(alpha_mask, uv).r;
}

// process function; takes the current UV followed by all uniforms in order
vec2 process(vec2 uv) {
	float value = sample_input(uv);
	float alpha = sample_alpha_mask(uv);
	return vec2(value, alpha);
}

// fragment function; for demo purposes
void fragment() {
	vec2 output = process(UV);
	COLOR = output.xxxy;
}
