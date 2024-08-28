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

vec3 rgb_to_hsv(vec3 p_color) {
	float f_max = max(max(p_color.r, p_color.g), p_color.b);
	float f_min = min(min(p_color.r, p_color.g), p_color.b);
	float f_delta = f_max - f_min;

	float h;
	if (f_delta < 0.0001) {
		h = 0.0f;
	} else {
		if (f_max - p_color.r < 0.0001) {
			h = 0.0 + (p_color.g - p_color.b) / f_delta;
		} else if (f_max - p_color.g < 0.0001) {
			h = 2.0 + (p_color.b - p_color.r) / f_delta;
		} else {
			h = 4.0 + (p_color.r - p_color.g) / f_delta;
		}
		h = fract(h / 6.0);
	}

	float s;
	if (f_max > 0.0001) {
		s = f_delta / f_max;
	} else {
		s = 0.0;
	}

	return vec3(h, s, f_max);
}

vec3 hsv_to_rgb(vec3 p_hsv) {
	float r;
	float g;
	float b;

	p_hsv.x = mod(p_hsv.x * 6.0, 6.0);
	float i;
	float f = modf(p_hsv.x, i);
	float p = p_hsv.z * (1.0f - p_hsv.y);
	float q = p_hsv.z * (1.0f - p_hsv.y * f);
	float t = p_hsv.z * (1.0f - p_hsv.y * (1.0f - f));

	switch (int(i)) {
		case 0: // Red is the dominant color
			r = p_hsv.z;
			g = t;
			b = p;
			break;
		case 1: // Green is the dominant color
			r = q;
			g = p_hsv.z;
			b = p;
			break;
		case 2:
			r = p;
			g = p_hsv.z;
			b = t;
			break;
		case 3: // Blue is the dominant color
			r = p;
			g = q;
			b = p_hsv.z;
			break;
		case 4:
			r = t;
			g = p;
			b = p_hsv.z;
			break;
		case 5: // Red is the dominant color
			r = p_hsv.z;
			g = p;
			b = q;
			break;
	}

	return vec3(r, g, b);
}