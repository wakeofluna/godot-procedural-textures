shader_type canvas_item;
render_mode unshaded;

// NAME:Normal Map

// samplers
uniform sampler2D bump_map;
// uniforms
uniform float bump_strength : hint_range(0.0, 32.0, 0.1) = 8.0f;

// indirection functions (required)
float sample_bump_map(vec2 uv) {
	return texture(bump_map, uv).x;
}

// process function (required); takes the current UV followed by all uniforms in order
vec3 process(vec2 uv, float p_bump_strength) {
	const vec2 uv_offset = vec2(1.0 / 1024.0, 1.0 / 1024.0);

	float f_here = sample_bump_map(uv);
	float f_across = sample_bump_map(uv + vec2(uv_offset.x, 0));
	float f_above = sample_bump_map(uv + vec2(0, uv_offset.y));

	vec3 up = vec3(0, 1, (f_here - f_above) * p_bump_strength);
	vec3 across = vec3(1, 0, (f_across - f_here) * p_bump_strength);
	vec3 normal = cross(across, up);
	normal = normalize(normal);

	return fma(normal, vec3(0.5), vec3(0.5));
}

// fragment function; for demo purposes
void fragment() {
	COLOR = vec4(process(UV, bump_strength), 1.0);
}
