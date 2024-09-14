shader_type canvas_item;
render_mode unshaded;

// NAME:Math

// samplers
uniform sampler2D input;
// uniforms
uniform float multiply : hint_range(-4.0, 4.0, 0.01) = 1.0;
uniform float add : hint_range(-1.0, 1.0) = 0.0;
uniform float power : hint_range(0.01, 10.0, 0.01) = 1.0;
uniform bool smooth_step = false;

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, float p_multiply, float p_add, float p_power, bool p_smooth_step) {
	vec4 value = sample_input(uv);
	value.rgb = fma(value.rgb, vec3(p_multiply), vec3(p_add));
	value.rgb = clamp(value.rgb, 0.0, 1.0);
	value.rgb = pow(value.rgb, vec3(p_power));
	if (p_smooth_step) {
		value.rgb = smoothstep(0.0, 1.0, value.rgb);
	}
	return value;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, multiply, add, power, smooth_step);
}
