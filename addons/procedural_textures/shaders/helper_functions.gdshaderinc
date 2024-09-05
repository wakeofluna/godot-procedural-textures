const vec2 uv_per_pixel = vec2(1.0 / 1023.0, 1.0 / 1023.0);

const vec3 luminance_factor = vec3(0.2126, 0.7152, 0.0722);

float get_luminance(vec4 p_color) {
	vec3 f_tmp = p_color.xyz * luminance_factor;
	return f_tmp.x + f_tmp.y + f_tmp.z;
}

vec2 degrees_to_phi(int p_angle) {
	float f_tmp = radians(float(p_angle));
	return vec2(cos(f_tmp), sin(f_tmp));
}

vec2 rotate_uv(vec2 p_uv, int p_angle) {
	vec2 v_phi = degrees_to_phi(p_angle);
	vec2 v_rotated;
	p_uv = p_uv - 0.5f;
	v_rotated.x = p_uv.x * v_phi.x - p_uv.y * v_phi.y;
	v_rotated.y = p_uv.y * v_phi.x + p_uv.x * v_phi.y;
	return v_rotated + 0.5f;
}

vec2 rotate_uv_phi(vec2 p_uv, vec2 p_phi) {
	vec2 v_rotated;
	p_uv = p_uv - 0.5f;
	v_rotated.x = p_uv.x * p_phi.x - p_uv.y * p_phi.y;
	v_rotated.y = p_uv.y * p_phi.x + p_uv.x * p_phi.y;
	return v_rotated + 0.5f;
}
