shader_type canvas_item;
render_mode unshaded;

// NAME:Layering

// samplers
uniform sampler2D input;
uniform sampler2D overlay;

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}
vec4 sample_overlay(vec2 uv) {
	return texture(overlay, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv) {
	vec4 value = sample_input(uv);
	vec4 layer = sample_overlay(uv);
	float new_alpha = fma(layer.a, (1.0 - value.a), value.a);
	return vec4(fma(layer.rgb, vec3(layer.a), value.rgb), new_alpha);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV);
}
