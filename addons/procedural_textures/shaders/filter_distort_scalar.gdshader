shader_type canvas_item;
render_mode unshaded;

// NAME:Distort (scalar)

// samplers
uniform sampler2D input;
// uniforms
uniform float zebra_scale : hint_range(0.0, 1.0) = 0.67;
uniform float zebra_amp : hint_range(0.0, 10.0) = 1.3;

// indirection functions (required)
float sample_input(vec2 uv) {
	return texture(input, uv).r;
}

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = smoothstep(0.0, 1.0, fract(p));
	return mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
	               dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), f.x),
	           mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
	               dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 n) {
	float total = 0.0, amp = 1.0;
	for (int i = 0; i < 7; i++) {
		total += noise(n) * amp;
		n += n;
		amp *= 0.5;
	}
	return total;
}

// process function; takes the current UV followed by all uniforms in order
float process(vec2 uv, float p_zebra_scale, float p_zebra_amp) {
	vec2 D = vec2(p_zebra_amp * fbm(uv * 2.0 / p_zebra_scale) * p_zebra_scale);
	return sample_input(uv + D);
}

// fragment function; for demo purposes
void fragment() {
	float output = process(UV, zebra_scale, zebra_amp);
	COLOR = vec4(output, output, output, 1.0);
}
