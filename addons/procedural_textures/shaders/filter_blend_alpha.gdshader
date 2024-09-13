shader_type canvas_item;
render_mode unshaded;

// NAME:Blend Alpha

// samplers
uniform sampler2D base;
uniform sampler2D overlay;

// indirection functions (required)
vec4 sample_base(vec2 uv) {
	return texture(base, uv);
}
vec4 sample_overlay(vec2 uv) {
	return texture(overlay, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv) {
	vec4 value = sample_base(uv);
	vec4 layer = sample_overlay(uv);
	float new_alpha = fma(value.a, (1.0 - layer.a), layer.a);
	return vec4(mix(value.rgb, layer.rgb, layer.a), new_alpha);
	//return vec4(fma(layer.rgb, vec3(layer.a), value.rgb), new_alpha);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV);
}
