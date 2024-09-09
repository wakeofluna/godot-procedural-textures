shader_type canvas_item;
render_mode unshaded;

// NAME:Transform

// samplers
uniform sampler2D input;
// uniforms
uniform float scale : hint_range(0.01, 20.0, 0.01) = 1.0f;
uniform int rotate : hint_range(0, 360) = 0;
uniform vec2 translate = vec2(0.0, 0.0);

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, float p_scale, int p_rotate, vec2 p_translate) {
	uv += p_translate;

	float rads = radians(float(p_rotate));
	vec2 v_phi = vec2(cos(rads), sin(rads));
	uv -= 0.5;
	vec2 new_uv;
	new_uv.x = uv.x * v_phi.x - uv.y * v_phi.y;
	new_uv.y = uv.y * v_phi.x + uv.x * v_phi.y;

	new_uv = fma(new_uv, vec2(p_scale), vec2(0.5));

	return sample_input(new_uv);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, scale, rotate, translate);
}
