shader_type canvas_item;
render_mode unshaded;

// NAME:Weave

// uniforms
uniform vec4 color_x : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_y : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width_x : hint_range(0.0f, 1.0f) = 0.85f;
uniform float width_y : hint_range(0.0f, 1.0f) = 0.85f;
uniform int stitch_x : hint_range(1, 10) = 1;
uniform int stitch_y : hint_range(1, 10) = 1;
uniform float depth : hint_range(0.0f, 1.0f) = 0.2f;

// process function; takes the current UV followed by all uniforms in order
vec4 process(vec2 uv, vec4 p_color_x, vec4 p_color_y, float p_width_x, float p_width_y, int p_stitch_x, int p_stitch_y, float p_depth) {
	vec2 stitch = vec2(float(p_stitch_x), float(p_stitch_y)) * 2.0;
	vec2 uv_fract = fract(uv * stitch);

	vec2 upper_margin = fma(vec2(p_width_x, p_width_y), vec2(0.5), vec2(0.5));
	vec2 lower_margin = vec2(1.0) - upper_margin;
	bool use_x = uv_fract.y >= lower_margin.y && uv_fract.y <= upper_margin.y;
	bool use_y = uv_fract.x >= lower_margin.x && uv_fract.x <= upper_margin.x;
	bool prefer_x = false;

	vec2 offset = floor(uv * 2.0);
	float block = abs(offset.x - offset.y);
	prefer_x = block > 0.5;
	uv_fract = fract(uv * 2.0);
	
	vec2 coverage;
	if (prefer_x) {
		coverage = sin((uv_fract + vec2(0.0, 1.0)) * PI);
	} else {
		coverage = sin((uv_fract + vec2(1.0, 0.0)) * PI);
	}

	coverage = fma(coverage, vec2(0.5), vec2(0.5));
	coverage = smoothstep(0.0, 1.0, coverage);
	coverage = fma(coverage, vec2(1.0 - p_depth), vec2(p_depth));
	vec4 col_x = vec4(p_color_x.rgb * coverage.x, p_color_x.a);
	vec4 col_y = vec4(p_color_y.rgb * coverage.y, p_color_y.a);
	
	if (use_x && use_y) {
		if (prefer_x) {
			float new_alpha = fma(col_y.a, (1.0 - col_x.a), col_x.a);
			return vec4(mix(col_y.rgb, col_x.rgb, col_x.a), new_alpha);
		} else {
			float new_alpha = fma(col_x.a, (1.0 - col_y.a), col_y.a);
			return vec4(mix(col_x.rgb, col_y.rgb, col_y.a), new_alpha);
		}
	} else if (use_x)
		return col_x;
	else if (use_y)
		return col_y;
	else
		return vec4(0, 0, 0, 0);
}

// fragment function; for demo purposes
void fragment() {
	COLOR = process(UV, color_x, color_y, width_x, width_y, stitch_x, stitch_y, depth);
}