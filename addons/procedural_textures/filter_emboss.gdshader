shader_type canvas_item;

uniform sampler2D input;
uniform sampler2D mask;
uniform int angle : hint_range(0, 360) = 45;
uniform float strength : hint_range(0.0, 32.0) = 4.0;


struct EmbossDef
{
	vec2 uv_angle_offset;
	float strength;
};

const vec3 luminance_factor = vec3(0.2126, 0.7152, 0.0722);

float luminance(vec4 color) {
	vec3 tmp = color.xyz * luminance_factor;
	return tmp.x + tmp.y + tmp.z;
}

vec4 emboss(EmbossDef def, vec2 uv, sampler2D p_input, sampler2D p_mask) {
	vec4 color_in = texture(p_input, uv);
	vec4 color_mask_1 = texture(p_mask, uv);
	vec4 color_mask_2 = texture(p_mask, uv + def.uv_angle_offset);
	float v = (luminance(color_mask_2) - luminance(color_mask_1)) * def.strength;
	return clamp(color_in + vec4(v, v, v, 0), 0.0, 1.0);
}


void fragment() {
	float rads = radians(float(angle));
	ivec2 mask_size = textureSize(mask, 0);

	EmbossDef emboss1 = EmbossDef(
		vec2(cos(rads), sin(rads)) / vec2(mask_size), strength
	);

	COLOR = emboss(emboss1, UV, input, mask);
}
