shader_type canvas_item;
render_mode unshaded;

// NAME:Layering (scalar)

// samplers
uniform sampler2D input;
uniform sampler2D overlay;

// indirection functions (required)
vec2 sample_input(vec2 uv) {
	return texture(input, uv).ra;
}
vec2 sample_overlay(vec2 uv) {
	return texture(overlay, uv).ra;
}

// process function; takes the current UV followed by all uniforms in order
vec2 process(vec2 uv) {
	vec2 value = sample_input(uv);
	vec2 layer = sample_overlay(uv);
	float new_alpha = fma(layer.y, (1.0 - value.y), value.y);
	return vec2(fma(layer.x, layer.y, value.x), new_alpha);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV).xxxy;
}
