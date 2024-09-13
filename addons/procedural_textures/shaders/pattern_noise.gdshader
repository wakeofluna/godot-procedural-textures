shader_type canvas_item;
render_mode unshaded;

// NAME:Noise

uniform float density : hint_range(2.0, 64.0) = 8.0;
uniform int octaves : hint_range(1, 16) = 7;
uniform vec2 translate = vec2(0.0, 0.0);

#include "noise.gdshaderinc"

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, float p_density, int p_octaves, vec2 p_translate) {
	return fractal_noise(fma(uv, vec2(p_density), p_translate), p_octaves);
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV, density, octaves, translate);
	COLOR = vec4(vec3(val), 1.0);
}