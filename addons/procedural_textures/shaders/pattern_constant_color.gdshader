shader_type canvas_item;
render_mode unshaded;

// NAME:Constant Color

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, vec4 p_color) {
	return p_color;
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, color);
}