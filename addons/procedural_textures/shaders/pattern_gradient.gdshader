shader_type canvas_item;
render_mode unshaded;

// NAME:Gradient

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv) {
	return uv.x;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV);
	COLOR = vec4(val, val, val, 1.0);
}