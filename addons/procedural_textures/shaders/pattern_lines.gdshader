shader_type canvas_item;
render_mode unshaded;

// NAME:Lines

uniform int nr_of_lines : hint_range(1, 32) = 4;
uniform int skew : hint_range(0, 32) = 0;
uniform int periods : hint_range(0, 32) = 4;
uniform float amplitude : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float thickness : hint_range(0.0f, 1.0f) = 0.1;


// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, int p_nr_of_lines, int p_skew, int p_periods, float p_amplitude, float p_thickness) {
	float min_dist = 999.9;
	float space_per_line = 1.0 / float(p_nr_of_lines);
	float line_offset = 0.5 * space_per_line;
	vec2 line_vector = vec2(1.0, float(p_skew) * space_per_line);
	float line_length2 = dot(line_vector, line_vector);
	float line_length = sqrt(line_length2);
	
	for (int i = -p_nr_of_lines-p_skew; i < 2 * p_nr_of_lines; ++i) {
		vec2 line_start = vec2(0.0, line_offset + float(i) * space_per_line);
		vec2 line_end = vec2(1.0, line_start.y + float(p_skew) * space_per_line);
		
		vec2 local = uv - line_start;
		float t = dot(local, line_vector) / line_length2;
		vec2 closest_point = t * line_vector + line_start;
		float dist = length(uv - closest_point);
		
		float wave = sin(t * float(p_periods) * 2.0 * PI) * p_amplitude;
		
		bool above = (local.x * -line_vector.y + local.y * line_vector.x) >= 0.0;
		if (above)
			dist += wave;
		else
			dist -= wave;
		
		min_dist = min(min_dist, abs(dist));
	}
	
	float val = min_dist * float(p_nr_of_lines);
	
	if (val >= p_thickness) {
		val = 0.0;
	} else {
		val = 1.0 - (val / p_thickness);
	}
	
	return val;
}

// fragment function; for demo purposes
void fragment() {
	float val = process(UV, nr_of_lines, skew, periods, amplitude, thickness);
	COLOR = vec4(vec3(val), 1.0);
}