shader_type canvas_item;
render_mode unshaded;

// NAME:Luminance

// samplers
uniform sampler2D input;

// process function; takes the def struct and the current UV
vec2 process(vec2 uv) {
	const vec3 luminance_factor = vec3(0.2126, 0.7152, 0.0722);
	vec4 color = texture(input, uv);
	vec3 tmp = color.xyz * luminance_factor;
	return vec2(tmp.x + tmp.y + tmp.z, color.a);
}

// fragment function; for demo purposes
void fragment() {
	vec2 luminance = process(UV);
	COLOR = vec4(luminance.x, luminance.x, luminance.x, luminance.y);
}
