shader_type canvas_item;
render_mode unshaded;

// NAME:Star

uniform int sections : hint_range(1, 64) = 7;
uniform float outer_size : hint_range(0.1, 1.0, 0.01) = 0.4;
uniform float inner_size : hint_range(0.1, 1.0, 0.01) = 0.3;
uniform float inner_edge : hint_range(0.1, 4.0, 0.01) = 2.0;
uniform float slope : hint_range(0.01, 5.0, 0.01) = 1.0;

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_sections, float p_outer_size, float p_inner_size, float p_inner_edge, float p_slope) {
	uv -= 0.5;
	float uv_len = sqrt(dot(uv, uv));
	float angle = acos(dot(uv / uv_len, vec2(0.0, 1.0)));
	float interval = 2.0 * PI / float(p_sections);
	float angle_dist = abs(angle - interval * round(angle / interval)) / interval * 2.0;

	float star_size = mix(p_inner_size, p_outer_size, pow(angle_dist, p_inner_edge));
	float value = uv_len / max(0.0001, star_size);

	value = smoothstep(0.0, 1.0, value);
	value = pow(value, p_slope);

	return 1.0 - value;
}

// fragment function; for demo purposes
void fragment() {
	float value = process(UV, sections, outer_size, inner_size, inner_edge, slope);
	COLOR = vec4(vec3(value), 1.0);
}