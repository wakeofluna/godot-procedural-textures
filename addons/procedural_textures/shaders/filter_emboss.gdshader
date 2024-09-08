shader_type canvas_item;
render_mode unshaded;

// NAME:Emboss

// samplers
uniform sampler2D input;
uniform sampler2D mask;
// uniforms
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, int p_angle, float p_strength) {
	const vec2 uv_offset = vec2(1.0 / 1024.0, 1.0 / 1024.0);

	float phi = radians(float(p_angle));
	vec2 uv_angle_offset = vec2(cos(phi), sin(phi)) * uv_offset;
	vec4 color_in = texture(input, uv);
	float val_mask_1 = texture(mask, uv).x;
	float val_mask_2 = texture(mask, uv + uv_angle_offset).x;
	float v = (val_mask_2 - val_mask_1) * p_strength;
	return clamp(color_in + vec4(v, v, v, 0), 0.0, 1.0);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, angle, strength);
}
