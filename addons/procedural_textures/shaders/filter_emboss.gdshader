shader_type canvas_item;
render_mode unshaded;

// NAME:Emboss

// samplers
uniform sampler2D input;
uniform sampler2D mask;
// uniforms
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;

// special const
const vec2 uv_per_pixel = vec2(1.0 / 1023.0, 1.0 / 1023.0);

// helper struct to pack uniforms
struct EmbossDef
{
	vec2 uv_angle_offset;
	float strength;
};

// make_def function; must have all arguments in same order as uniforms
EmbossDef make_def(int p_angle, float p_strength) {
	float phi = radians(float(p_angle));
	return EmbossDef(
		vec2(cos(phi), sin(phi)) * uv_per_pixel, p_strength
	);
}

// process function; takes the def struct and the current UV
vec4 process(EmbossDef def, vec2 uv) {
	vec4 color_in = texture(input, uv);
	float val_mask_1 = texture(mask, uv).x;
	float val_mask_2 = texture(mask, uv + def.uv_angle_offset).x;
	float v = (val_mask_2 - val_mask_1) * def.strength;
	return clamp(color_in + vec4(v, v, v, 0), 0.0, 1.0);
}

// fragment function; for demo purposes
void fragment() {
	EmbossDef def = make_def(angle, strength);
	COLOR = process(def, UV);
}
