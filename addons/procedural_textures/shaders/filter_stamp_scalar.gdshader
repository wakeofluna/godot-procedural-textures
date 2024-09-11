shader_type canvas_item;
render_mode unshaded;

// NAME:Stamp (scalar)

// samplers
uniform sampler2D stamp;
// uniforms
uniform int nr_of_stamps : hint_range(2, 64) = 8;
uniform float stamp_size : hint_range(0.01, 2.0, 0.01) = 0.25;
uniform int jitter_seed : hint_range(0, 64) = 0;
uniform float jitter_strength : hint_range(0.0, 5.0, 0.01) = 0.0;

#include "prng.gdshaderinc"

// indirection functions (required)
vec2 sample_stamp(vec2 uv) {
	return texture(stamp, uv).ra;
}

// process function; takes the current UV followed by all uniforms in order
vec2 process(vec2 uv, int p_nr_of_stamps, float p_stamp_size, int p_jitter_seed, float p_jitter_strength) {
	p_stamp_size *= 0.5;
	vec2 inv_stamp_size = vec2(0.5 / p_stamp_size);
	float rows = ceil(sqrt(float(p_nr_of_stamps)));
	float jit_strength = float(p_jitter_strength) * 0.2;

	int rand_state = p_jitter_seed + 1;

	vec2 value = vec2(0.0);
	for (int i = 0; i < p_nr_of_stamps; i += 1) {
		vec2 pos;
		pos.y = float(i) / float(p_nr_of_stamps);
		pos.x = fract(pos.y * rows);

		vec2 jitter = vec2(prng(rand_state), prng(rand_state)) - 0.5;
		pos = pos + jitter * jit_strength;

		vec2 offset = pos - uv;
		if (offset.x > 0.5) {
			offset.x = offset.x - 1.0;
		} else if (offset.x < -0.5) {
			offset.x = offset.x + 1.0;
		}
		if (offset.y > 0.5) {
			offset.y = offset.y - 1.0;
		} else if (offset.y < -0.5) {
			offset.y = offset.y + 1.0;
		}

		if (abs(offset.x) < p_stamp_size && abs(offset.y) < p_stamp_size) {
			offset = fma(offset, inv_stamp_size, vec2(0.5));
			vec2 inp = sample_stamp(offset);
			if (inp.y > 0.0) {
				float blend = value.y * (1.0 - inp.y);
				vec2 new_value;
				new_value.y = inp.y + blend;
				new_value.x = (inp.x * inp.y + value.x * blend) / new_value.y;
				value = new_value;
			}
		}
	}
	return value;
}

// fragment function; for demo purposes
void fragment() {
	vec2 output = process(UV, nr_of_stamps, stamp_size, jitter_seed, jitter_strength);
	COLOR = output.xxxy;
}
