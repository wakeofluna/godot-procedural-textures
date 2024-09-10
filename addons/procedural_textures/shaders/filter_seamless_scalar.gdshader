shader_type canvas_item;
render_mode unshaded;

// NAME:Seamless (scalar)

// samplers
uniform sampler2D input;
uniform float blend_skirt : hint_range(0.0, 0.5, 0.01) = 0.1;
uniform bool tile = false;

// indirection functions (required)
vec2 sample_input(vec2 uv) {
	return texture(input, uv).ra;
}

// process function; takes the current UV followed by all uniforms in order
vec2 process(vec2 uv, float p_blend_skirt, bool p_tile) {
	uv = fract(uv);

	float skirt_strength = 0.5 / p_blend_skirt;

	vec2 other;
	vec2 strength;
	bool do_x;
	bool do_y;
	if (uv.x < p_blend_skirt) {
		other.x = -uv.x;
		strength.x = fma(uv.x, skirt_strength, 0.5);
		do_x = true;
	} else if (1.0 - uv.x < p_blend_skirt) {
		other.x = 2.0 - uv.x;
		strength.x = fma(1.0 - uv.x, skirt_strength, 0.5);
		do_x = true;
	} else {
		do_x = false;
	}

	if (uv.y < p_blend_skirt) {
		other.y = -uv.y;
		strength.y = fma(uv.y, skirt_strength, 0.5);
		do_y = true;
	} else if (1.0 - uv.y < p_blend_skirt) {
		other.y = 2.0 - uv.y;
		strength.y = fma(1.0 - uv.y, skirt_strength, 0.5);
		do_y = true;
	} else {
		do_y = false;
	}

	if (p_tile) {
		other = fract(other);
	}

	vec2 here = sample_input(uv);
	if (do_x && do_y) {
		vec2 x2 = sample_input(vec2(other.x, uv.y));
		vec2 y2 = sample_input(vec2(uv.x, other.y));
		vec2 xy = sample_input(other);
		vec2 _x = mix(x2, here, strength.x);
		vec2 _y = mix(xy, y2, strength.x);
		here = mix(_y, _x, strength.y);
	} else if (do_x) {
		vec2 x2 = sample_input(vec2(other.x, uv.y));
		here = mix(x2, here, strength.x);
	} else if (do_y) {
		vec2 y2 = sample_input(vec2(uv.x, other.y));
		here = mix(y2, here, strength.y);
	}

	return here;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, blend_skirt, tile).xxxy;
}
