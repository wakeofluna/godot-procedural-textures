shader_type canvas_item;
render_mode unshaded;

// NAME:Bricks

// uniforms
uniform int count_x : hint_range(1, 20) = 4;
uniform int count_y : hint_range(1, 20) = 10;
uniform float row_shift : hint_range(0.0f, 1.0f) = 0.5f;
uniform float gap_x : hint_range(0.0f, 1.0f) = 0.0f;
uniform float gap_y : hint_range(0.0f, 1.0f) = 0.0f;
uniform float smoothing : hint_range(0.0f, 0.5f) = 0.1f;

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_count_x, int p_count_y, float p_row_shift, float p_gap_x, float p_gap_y, float p_smoothing) {
	float norm_x = float(max(1, p_count_x));
	float norm_y = float(max(1, p_count_y));
	float uu = uv.x * norm_x;
	float vv = uv.y * norm_y;
	float row = floor(vv);
	uu = uu - row * p_row_shift;

	float y = vv - row;
	float x = uu - floor(uu);

	float dist_x = max(0.0, x - p_gap_x);
	float dist_y = max(0.0, y - p_gap_y);

	float min_dist_x = min(dist_x, 1.0f - x) / norm_x;
	float min_dist_y = min(dist_y, 1.0f - y) / norm_y;
	float min_dist = min(min_dist_x, min_dist_y);
	float dist = min_dist * min(norm_x, norm_y);
	float val = min(1.0f, dist / max(p_smoothing, 0.00001));

	return val;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV, count_x, count_y, row_shift, gap_x, gap_y, smoothing);
	COLOR = vec4(val, val, val, 1.0);
}