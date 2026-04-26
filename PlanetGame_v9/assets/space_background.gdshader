shader_type sky;

uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float star_brightness : hint_range(0.0, 5.0) = 1.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void sky() {
	vec3 dir = EYEDIR;
	// Create a stable grid for stars based on direction
	vec2 uv = vec2(atan(dir.z, dir.x), acos(dir.y)) * 100.0;
	vec2 id = floor(uv);
	
	float h = hash(id);
	float star = 0.0;
	
	if (h > (1.0 - 0.02 * star_density)) {
		// Calculate distance from center of "cell"
		float dist = distance(fract(uv), vec2(0.5));
		// Sharp circular dots
		star = smoothstep(0.1 * h, 0.0, dist) * star_brightness;
		// Subtle flickering
		star *= mix(0.7, 1.0, hash(id + TIME * 0.001));
	}
	
	COLOR = vec3(star);
}
