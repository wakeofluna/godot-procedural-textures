shader_type canvas_item;
render_mode unshaded;

// NAME:Emboss (scalar)

// samplers
uniform sampler2D input;
uniform sampler2D mask;
// uniforms
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).x;
}
float sample_mask(vec2 uv) {
	return texture(mask, uv).x;
}

// process function (required); takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_angle, float p_strength) {
	const vec2 uv_offset = vec2(1.0 / 1024.0, 1.0 / 1024.0);

	float phi = radians(float(p_angle));
	vec2 uv_angle_offset = vec2(cos(phi), sin(phi)) * uv_offset;
	float color_in = sample_input(uv);
	float val_mask_1 = sample_mask(uv);
	float val_mask_2 = sample_mask(uv + uv_angle_offset);
	float v = (val_mask_2 - val_mask_1) * p_strength;
	return clamp(color_in + v, 0.0, 1.0);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = vec4(vec3(process(UV, angle, strength)), 1.0);
}
