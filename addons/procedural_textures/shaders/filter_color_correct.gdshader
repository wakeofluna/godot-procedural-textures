shader_type canvas_item;

// NAME:ColorCorrect

// samplers
uniform sampler2D input;
// uniforms
uniform float brightness : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float contrast : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float hue_shift : hint_range(0.0, 360.0, 0.1) = 0.0;
uniform float desaturate : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float gamma : hint_range(0.1, 3.0, 0.01) = 1.0;

#include "helper_functions.gdshaderinc"

// helper struct to pack uniforms
struct ColorCorrectDef {
	float brightness;
	float contrast;
	float hue_shift;
	float desaturate;
	float gamma;
};

// definition function; must have all arguments in same order as uniforms
ColorCorrectDef make_def(float p_brightness, float p_contrast, float p_hue_shift, float p_desaturate, float p_gamma) {
	return ColorCorrectDef(
		p_brightness + 0.5, p_contrast, p_hue_shift, p_desaturate, p_gamma
	);
}

// process function; takes the def struct and the current UV
vec4 process(ColorCorrectDef def, vec2 uv) {
	vec4 v_color = texture(input, uv);
	v_color.rgb -= 0.5f;
	v_color.rgb = fma(v_color.rgb, vec3(def.contrast), vec3(def.brightness));
	v_color.rgb = clamp(v_color.rgb, 0.0, 1.0);

	vec3 hsv = rgb_to_hsv(v_color.rgb);
	hsv.x = fract(hsv.x + def.hue_shift / 360.0);
	hsv.y *= 1.0 - def.desaturate;
	v_color.rgb = hsv_to_rgb(hsv);

	v_color.rgb = pow(v_color.rgb, vec3(def.gamma));

	return v_color;
}

// fragment function; for demo purposes
void fragment() {
	ColorCorrectDef def = make_def(brightness, contrast, hue_shift, desaturate, gamma);
	COLOR = process(def, UV);
}
