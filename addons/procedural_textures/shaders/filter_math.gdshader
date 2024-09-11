shader_type canvas_item;
render_mode unshaded;

// NAME:Math (scalar)

// samplers
uniform sampler2D input;
// uniforms
uniform float multiply : hint_range(-2.0, 2.0, 0.01) = 1.0;
uniform float add : hint_range(-1.0, 1.0) = 0.0;
uniform float power : hint_range(0.01, 10.0, 0.01) = 1.0;
uniform bool smooth_step = false;

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).r;
}

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, float p_multiply, float p_add, float p_power, bool p_smooth_step) {
	float value = sample_input(uv);
	value = fma(value, p_multiply, p_add);
	value = clamp(value, 0.0, 1.0);
	value = pow(value, p_power);
	if (p_smooth_step) {
		value = smoothstep(0.0, 1.0, value);
	}
	return value;
}

// fragment function; for demo purposes
void fragment() {
	float output = process(UV, multiply, add, power, smooth_step);
	COLOR = vec4(vec3(output), 1.0);
}
