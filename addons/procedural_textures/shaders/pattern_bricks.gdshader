shader_type canvas_item;

// NAME:Bricks

// uniforms
uniform int count_x : hint_range(1, 20) = 4;
uniform int count_y : hint_range(1, 20) = 10;
uniform float row_shift : hint_range(0.0f, 1.0f) = 0.5f;
uniform float gap_x : hint_range(0.0f, 1.0f) = 0.0f;
uniform float gap_y : hint_range(0.0f, 1.0f) = 0.0f;
uniform float smoothing : hint_range(0.0f, 0.5f) = 0.1f;
uniform int rotation : hint_range(-180, 180) = 0;

#include "helper_functions.gdshaderinc"

// helper struct to pack uniforms
struct BrickDef
{
	float norm_x;
	float norm_y;
	float row_shift;
	float gap_x;
	float gap_y;
	float smoothing;
	vec2 phi;
};

// make_def function; must have all arguments in same order as uniforms
BrickDef make_def(int p_count_x, int p_count_y, float p_row_shift, float p_gap_x, float p_gap_y, float p_smoothing, int p_rotation) {
	return BrickDef(
		float(p_count_x), float(p_count_y), p_row_shift, p_gap_x, p_gap_y, p_smoothing, degrees_to_phi(p_rotation)
	);
}

// process function; takes the def struct and the current UV
float process(BrickDef def, vec2 uv) {
	uv = rotate_uv_phi(uv, def.phi);

	float uu = uv.x * def.norm_x;
	float vv = uv.y * def.norm_y;
	float row = floor(vv);
	uu = uu - row * def.row_shift;

	float y = vv - row;
	float x = uu - floor(uu);

	float dist_x = x - def.gap_x;
	float dist_y = y - def.gap_y;

	float min_dist_x = min(dist_x, 1.0f - x) / def.norm_x;
	float min_dist_y = min(dist_y, 1.0f - y) / def.norm_y;
	float min_dist = min(min_dist_x, min_dist_y);
	float dist = min_dist * min(def.norm_x, def.norm_y);
	float val = min(1.0f, dist / max(def.smoothing, 0.0001));

	return val;
}

// fragment function; for demo purposes
void fragment() {
	BrickDef def = make_def(count_x, count_y, row_shift, gap_x, gap_y, smoothing, rotation);
	float val = process(def, UV);
	COLOR = vec4(val, val, val, 1.0);
}