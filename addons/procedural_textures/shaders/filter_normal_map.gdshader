shader_type canvas_item;
render_mode unshaded;

// NAME:Normal Map

// samplers
uniform sampler2D bump_map;
// uniforms
uniform float bump_strength : hint_range(0.0, 32.0, 0.1) = 8.0f;

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, float p_bump_strength) {
	const vec2 uv_offset = vec2(1.0 / 1024.0, 1.0 / 1024.0);

	float f_here = texture(bump_map, uv).x;
	float f_across = texture(bump_map, uv + vec2(uv_offset.x, 0)).x;
	float f_above = texture(bump_map, uv + vec2(0, uv_offset.y)).x;

	vec3 up = vec3(0, 1, (f_here - f_above) * p_bump_strength);
	vec3 across = vec3(1, 0, (f_across - f_here) * p_bump_strength);
	vec3 normal = cross(across, up);
	normal = normalize(normal);

	return vec4(fma(normal, vec3(0.5), vec3(0.5)), 1.0);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, bump_strength);
}
