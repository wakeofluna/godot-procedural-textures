shader_type canvas_item;
render_mode unshaded;

// NAME:Circle Gradient

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv) {
	uv -= 0.5;
	float val = sqrt(dot(uv, uv)) * 2.0;
	return 1.0 - val;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV);
	COLOR = vec4(val, val, val, 1.0);
}