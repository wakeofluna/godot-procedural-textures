shader_type canvas_item;
render_mode unshaded;

// NAME:Alpha Set

// samplers
uniform sampler2D input;
uniform sampler2D alpha_mask;

// indirection functions (required)
vec3 sample_input(vec2 uv) {
	return texture(input, uv).rgb;
}
float sample_alpha_mask(vec2 uv) {
	return texture(alpha_mask, uv).r;
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv) {
	vec3 value = sample_input(uv);
	float alpha = sample_alpha_mask(uv);
	return vec4(value, alpha);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV);
}
