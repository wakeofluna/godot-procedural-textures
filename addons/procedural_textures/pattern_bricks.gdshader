shader_type canvas_item;

// bricks
uniform vec4 color_seams : source_color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
uniform vec4 color_bricks : source_color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
uniform int count_x : hint_range(1, 20) = 4;
uniform int count_y : hint_range(1, 20) = 10;
uniform float row_shift : hint_range(0.0f, 1.0f) = 0.5f;
uniform float gap_x : hint_range(0.0f, 1.0f) = 0.0f;
uniform float gap_y : hint_range(0.0f, 1.0f) = 0.0f;
uniform float smoothing : hint_range(0.0f, 0.5f) = 0.1f;
uniform int rotation : hint_range(-180, 180) = 0;

struct BrickDef
{
	vec4 color_seams;
	vec4 color_bricks;
	float norm_x;
	float norm_y;
	float row_shift;
	float gap_x;
	float gap_y;
	float smoothing;
};

float brick_strength(BrickDef def, vec2 uv)
{
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

vec2 rotate(vec2 uv, float angle)
{
	float cos_phi = cos(angle);
	float sin_phi = sin(angle);
	vec2 rotated;
	rotated.x = (uv.x - 0.5f) * cos_phi + (uv.y - 0.5f) * sin_phi + 0.5f;
	rotated.y = (uv.y - 0.5f) * cos_phi - (uv.x - 0.5f) * sin_phi + 0.5f;
	return rotated;
}

void fragment() {
	BrickDef bricks1 = BrickDef(
		color_seams, color_bricks, float(count_x), float(count_y), row_shift, gap_x, gap_y, smoothing
	);

	float angle = radians(float(rotation));
	vec2 uv = rotate(UV, angle);

	float brick_strength = brick_strength(bricks1, uv);
	vec4 brick_color = mix(color_seams, color_bricks, brick_strength);
	COLOR = brick_color;
}
