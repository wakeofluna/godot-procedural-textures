shader_type canvas_item;
render_mode unshaded;

// NAME:Seamless

// samplers
uniform sampler2D input;
uniform float blend_skirt : hint_range(0.0, 0.5, 0.01) = 0.1;
uniform bool input_is_tiled = false;

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, float p_blend_skirt, bool p_input_is_tiled) {
	uv = fract(uv);
	p_blend_skirt = max(p_blend_skirt, 0.00001);
	float skirt_strength = 0.5 / p_blend_skirt;

	vec2 other;
	vec2 strength;
	bool do_x;
	bool do_y;
	if (uv.x < p_blend_skirt) {
		other.x = uv.x + 1.0;
		strength.x = fma(uv.x, skirt_strength, 0.5);
		do_x = true;
	} else if (1.0 - uv.x < p_blend_skirt) {
		other.x = uv.x - 1.0;
		strength.x = fma(1.0 - uv.x, skirt_strength, 0.5);
		do_x = true;
	} else {
		do_x = false;
	}

	if (uv.y < p_blend_skirt) {
		other.y = uv.y + 1.0;
		strength.y = fma(uv.y, skirt_strength, 0.5);
		do_y = true;
	} else if (1.0 - uv.y < p_blend_skirt) {
		other.y = uv.y - 1.0;
		strength.y = fma(1.0 - uv.y, skirt_strength, 0.5);
		do_y = true;
	} else {
		do_y = false;
	}

	if (p_input_is_tiled) {
		float stretch = 1.0 / fma(p_blend_skirt, 2.0, 1.0);
		uv = fma(uv - 0.5, vec2(stretch), vec2(0.5));
		other = fma(other - 0.5, vec2(stretch), vec2(0.5));
	}

	vec4 here = sample_input(uv);
	if (do_x && do_y) {
		vec4 x2 = sample_input(vec2(other.x, uv.y));
		vec4 y2 = sample_input(vec2(uv.x, other.y));
		vec4 xy = sample_input(other);
		vec4 _x = mix(x2, here, strength.x);
		vec4 _y = mix(xy, y2, strength.x);
		here = mix(_y, _x, strength.y);
	} else if (do_x) {
		vec4 x2 = sample_input(vec2(other.x, uv.y));
		here = mix(x2, here, strength.x);
	} else if (do_y) {
		vec4 y2 = sample_input(vec2(uv.x, other.y));
		here = mix(y2, here, strength.y);
	}

	return here;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, blend_skirt, input_is_tiled);
}
