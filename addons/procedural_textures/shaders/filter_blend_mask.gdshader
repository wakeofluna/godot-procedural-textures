shader_type canvas_item;
render_mode unshaded;

// NAME:Blend Mask

// samplers
uniform sampler2D base;
uniform sampler2D overlay;
uniform sampler2D mask;

// indirection functions (required)
vec4 sample_base(vec2 uv) {
	return texture(base, uv);
}
vec4 sample_overlay(vec2 uv) {
	return texture(overlay, uv);
}
float sample_mask(vec2 uv) {
	return texture(mask, uv).r;
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv) {
	vec4 value = sample_base(uv);
	vec4 layer = sample_overlay(uv);
	float factor = sample_mask(uv);
	return mix(value, layer, factor);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV);
}
