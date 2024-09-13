shader_type canvas_item;
render_mode unshaded;

// NAME:Cellular
// CREDITS:https://godotshaders.com/shader/cracked-glass/

#include "noise.gdshaderinc"

// uniforms
uniform int density : hint_range(1, 20) = 4;
uniform float profile : hint_range(0.1, 2.0, 0.1) = 1.0;
uniform float slope : hint_range(0.0, 20.0) = 10.0;
uniform float thickness : hint_range(-0.2, 0.2, 0.01) = 0.0;
uniform float jitter_strength : hint_range(0.0, 1.2, 0.01) = 1.0;
uniform int jitter_seed : hint_range(0, 64) = 0;

float voronoi(vec2 u, int p_wrap, float p_jitter_strength, int p_seed) {
	vec2 rand_offset = vec2(float(p_seed * p_wrap));
	vec2 p = floor(u);
	vec2 f = fract(u);
	float res = 8.0;
	vec2 C = vec2(0.0);
	vec2 P = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash(mod(p + g, float(p_wrap)) + rand_offset) * p_jitter_strength;
			vec2 r = g - f + o;
			float d = dot(r, r);
			if (d < res) {
				res = d;
				C = g;
				P = r;
			}
		}
	}
	res = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 g = C + vec2(float(i), float(j));
			vec2 o = hash(mod(p + g, float(p_wrap)) + rand_offset) * p_jitter_strength;
			vec2 r = g - f + o;
			if (dot(P - r, P - r) > 1e-5) {
				res = min(res, 0.5 * dot(P + r, normalize(r - P)));
			}
		}
	}
	return res;
}

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_density, float p_profile, float p_slope, float p_thickness, float p_jitter_strength, int p_jitter_seed) {
	uv *= float(p_density);
	float d = voronoi(uv, p_density, p_jitter_strength, p_jitter_seed);
	d = min(1.0, p_slope * pow(max(0.0, d - p_thickness), p_profile));
	return 1.0 - d;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV, density, profile, slope, thickness, jitter_strength, jitter_seed);
	COLOR = vec4(vec3(val), 1.0);
}