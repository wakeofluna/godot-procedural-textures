shader_type canvas_item;
render_mode unshaded;

// NAME:Circle Gradient
uniform float inner_radius : hint_range(-1.0, 1.0) = 0.0;
uniform float outer_radius : hint_range(0.0, 2.0) = 0.5;

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, float p_inner_radius, float p_outer_radius) {
	uv -= 0.5;
	float min_radius = min(p_outer_radius, p_inner_radius);
	float max_radius = max(p_outer_radius, p_inner_radius);
	float radius = sqrt(dot(uv, uv));
	float ratio;
	if (radius <= min_radius) {
		ratio = 0.0;
	} else if (radius >= max_radius) {
		ratio = 1.0;
	} else {
		ratio = (radius - min_radius) / (max_radius - min_radius);
	}
	if (p_inner_radius <= p_outer_radius)
		ratio = 1.0 - ratio;
	return ratio;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV, inner_radius, outer_radius);
	COLOR = vec4(val, val, val, 1.0);
}