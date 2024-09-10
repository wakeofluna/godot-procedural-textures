shader_type canvas_item;
render_mode unshaded;

// NAME:ColorCorrect

// samplers
uniform sampler2D input;
// uniforms
uniform float brightness : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float contrast : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float hue_shift : hint_range(0.0, 360.0, 0.1) = 0.0;
uniform float desaturate : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float gamma : hint_range(0.1, 3.0, 0.01) = 1.0;

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

// indirection functions (required)
vec3 sample_input(vec2 uv) {
	return texture(input, uv).rgb;
}

// process function (required); takes the current UV followed by all uniforms in order
vec3 process(vec2 uv, float p_brightness, float p_contrast, float p_hue_shift, float p_desaturate, float p_gamma) {
	vec3 v_color = sample_input(uv);
	v_color -= 0.5f;
	v_color = fma(v_color, vec3(p_contrast), vec3(p_brightness + 0.5));
	v_color = clamp(v_color, 0.0, 1.0);

	vec3 hsv = rgb_to_hsv(v_color);
	hsv.x = fract(hsv.x + p_hue_shift / 360.0);
	hsv.y *= 1.0 - p_desaturate;
	v_color = hsv_to_rgb(hsv);

	v_color = pow(v_color, vec3(p_gamma));

	return v_color;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = vec4(process(UV, brightness, contrast, hue_shift, desaturate, gamma), 1.0);
}
