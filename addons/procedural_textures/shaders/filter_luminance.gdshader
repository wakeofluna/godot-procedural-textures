shader_type canvas_item;
render_mode unshaded;

// NAME:Luminance

// samplers
uniform sampler2D input;

// indirection functions (required)
vec3 sample_input(vec2 uv) {
	return texture(input, uv).rgb;
}

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv) {
	const vec3 luminance_factor = vec3(0.2126, 0.7152, 0.0722);
	vec3 color = sample_input(uv);
	vec3 tmp = color.xyz * luminance_factor;
	return tmp.x + tmp.y + tmp.z;
}

// fragment function; for demo purposes
void fragment() {
	float luminance = process(UV);
	COLOR = vec4(luminance, luminance, luminance, 1.0);
}
