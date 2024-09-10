shader_type canvas_item;
render_mode unshaded;

// NAME:Transform

// samplers
uniform sampler2D input;
// uniforms
uniform vec2 scale = vec2(1.0, 1.0);
uniform int rotate : hint_range(0, 360) = 0;
uniform vec2 translate = vec2(0.0, 0.0);

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, vec2 p_scale, int p_rotate, vec2 p_translate) {
	uv += p_translate;

	if (p_rotate != 0) {
		float rads = radians(float(p_rotate));
		vec2 v_phi = vec2(cos(rads), sin(rads));
		uv -= 0.5;
		vec2 new_uv;
		new_uv.x = uv.x * v_phi.x - uv.y * v_phi.y;
		new_uv.y = uv.y * v_phi.x + uv.x * v_phi.y;
		uv = new_uv + 0.5;
	}

	uv /= p_scale;

	return sample_input(uv);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, scale, rotate, translate);
}
