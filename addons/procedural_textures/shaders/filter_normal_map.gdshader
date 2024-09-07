shader_type canvas_item;
render_mode unshaded;

// NAME:Normal Map

// samplers
uniform sampler2D bump_map;
// uniforms
uniform float bump_strength : hint_range(0.0, 32.0, 0.1) = 8.0f;

// special const
const vec2 uv_per_pixel = vec2(1.0 / 1023.0, 1.0 / 1023.0);

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, float p_bump_strength) {
	vec2 uv_offset = uv_per_pixel * 0.5;
	float across_1 = texture(bump_map, uv - vec2(uv_offset.x, 0)).x;
	float across_2 = texture(bump_map, uv + vec2(uv_offset.x, 0)).x;
	float above_1 = texture(bump_map, uv - vec2(0, uv_offset.y)).x;
	float above_2 = texture(bump_map, uv + vec2(0, uv_offset.y)).x;

	vec3 up = vec3(0, 1, (above_1 - above_2) * p_bump_strength);
	vec3 across = vec3(1, 0, (across_2 - across_1) * p_bump_strength);
	vec3 normal = cross(across, up);
	normal = normalize(normal);

	return vec4(fma(normal, vec3(0.5), vec3(0.5)), 1.0);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, bump_strength);
}
