shader_type canvas_item;
render_mode unshaded;

// NAME:Tile

// samplers
uniform sampler2D input;
// uniforms
uniform int tile_x : hint_range(1, 32) = 2;
uniform int tile_y : hint_range(1, 32) = 2;
uniform bool mirror_x = false;
uniform bool mirror_y = false;

// indirection functions (required)
vec4 sample_input(vec2 uv) {
	return texture(input, uv);
}

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, int p_tile_x, int p_tile_y, bool p_mirror_x, bool p_mirror_y) {
	uv.x *= float(p_tile_x);
	uv.y *= float(p_tile_y);

	if (p_mirror_x) {
		float col;
		uv.x = modf(uv.x, col);
		if (int(col) % 2 == 1) {
			uv.x = 1.0 - uv.x;
		}
	} else {
		uv.x = fract(uv.x);
	}

	if (p_mirror_y) {
		float row;
		uv.y = modf(uv.y, row);
		if (int(row) % 2 == 1) {
			uv.y = 1.0 - uv.y;
		}
	} else {
		uv.y = fract(uv.y);
	}

	return sample_input(uv);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, tile_x, tile_y, mirror_x, mirror_y);
}
