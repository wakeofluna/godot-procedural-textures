shader_type canvas_item;
render_mode unshaded;

// NAME:Infinity

uniform int rays : hint_range(1, 32) = 8;
uniform float slope : hint_range(0.01, 8.0, 0.01) = 1.0;

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_rays, float p_slope) {
	uv -= 0.5;
	float uv_len = sqrt(dot(uv, uv));
	float angle = acos(dot(uv / uv_len, vec2(0.0, 1.0)));
	float interval = 2.0 * PI / float(p_rays);
	float angle_dist = abs(angle - interval * round(angle / interval)) / interval * 2.0;

	angle_dist = pow(angle_dist, p_slope);

	return angle_dist;
}

// fragment function; for demo purposes
void fragment() {
	float value = process(UV, rays, slope);
	COLOR = vec4(vec3(value), 1.0);
}