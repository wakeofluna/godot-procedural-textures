shader_type canvas_item;
render_mode unshaded;

// NAME:Stamp

// samplers
uniform sampler2D stamp;
// uniforms
uniform int nr_of_stamps : hint_range(2, 64) = 8;
uniform float stamp_size : hint_range(0.01, 2.0, 0.01) = 0.25;
uniform float rotate_stamps : hint_range(0.0, 1.0) = 0.2;
uniform int jitter_seed : hint_range(0, 64) = 0;
uniform float jitter_strength : hint_range(0.0, 5.0, 0.01) = 0.0;

#include "prng.gdshaderinc"

// indirection functions (required)
vec4 sample_stamp(vec2 uv) {
	return texture(stamp, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, int p_nr_of_stamps, float p_stamp_size, float p_rotate_stamps, int p_jitter_seed, float p_jitter_strength) {
	p_stamp_size *= 0.5;
	vec2 inv_stamp_size = vec2(0.5 / p_stamp_size);
	float rows = ceil(sqrt(float(p_nr_of_stamps)));
	float jit_strength = float(p_jitter_strength) * 0.2;

	int rand_state = p_jitter_seed + 1;

	vec4 value = vec4(0.0);
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

		float rads = 2.0 * PI * fma(prng(rand_state), 2.0, -1.0) * p_rotate_stamps;
		vec2 phi = vec2(cos(rads), sin(rads));

		offset = offset * inv_stamp_size;
		vec2 new_off;
		new_off.x = offset.x * phi.x - offset.y * phi.y;
		new_off.y = offset.y * phi.x + offset.x * phi.y;
		offset = new_off + 0.5;
		if (floor(offset.x) == 0.0 && floor(offset.y) == 0.0) {
			vec4 inp = sample_stamp(offset);
			if (inp.a > 0.0) {
				float blend = value.a * (1.0 - inp.a);
				vec4 new_value;
				new_value.a = inp.a + blend;
				new_value.rgb = (inp.rgb * inp.a + value.rgb * blend) / new_value.a;
				value = new_value;
			}
		}
	}
	return value;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, nr_of_stamps, stamp_size, rotate_stamps, jitter_seed, jitter_strength);
}
