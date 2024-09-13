vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

vec2 noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = smoothstep(0.0, 1.0, f);
	f = mix(mix(hash(i + vec2(0.0, 0.0)),
	            hash(i + vec2(1.0, 0.0)), f.x),
	        mix(hash(i + vec2(0.0, 1.0)),
	            hash(i + vec2(1.0, 1.0)), f.x), f.y);
	return f;
}

float noise(vec2 p) {
	vec2 f = noise2(p);
	return dot(f, f) * 0.5;
}

vec2 fractal_noise2(vec2 n, int p_octaves) {
    vec2 total = vec2(0.0);
	float scale = 0.0, amp = 1.0;
    for (int i = 0; i < p_octaves; i++) {
        total += noise2(n) * amp;
        n += n;
		scale += amp;
        amp *= 0.5;
    }
    return smoothstep(0.0, 1.0, pow(total / scale, vec2(0.8)));
}

float fractal_noise(vec2 n, int p_octaves) {
	vec2 f = fractal_noise2(n, p_octaves);
	return dot(f, f) * 0.5;
}