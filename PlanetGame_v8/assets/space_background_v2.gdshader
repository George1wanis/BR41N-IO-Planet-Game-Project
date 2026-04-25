shader_type sky;

uniform vec3 bg_color : source_color = vec3(0.005, 0.005, 0.01);
uniform vec3 nebula_color : source_color = vec3(0.02, 0.01, 0.04);
uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float star_brightness : hint_range(0.0, 2.0) = 0.8;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 0.5;

// Deterministic noise function for stars
float hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 dir = EYEDIR;
	
	// 1. Subtle Nebula Gradient (Slow & Deep)
	float nebula_noise = hash(dir * 1.5 + TIME * 0.005);
	vec3 final_bg = mix(bg_color, nebula_color, nebula_noise * 0.4);
	
	// 2. Distant Starfield (Small, subtle dots)
	vec3 star_grid = dir * 300.0;
	vec3 ipos = floor(star_grid);
	float star_val = hash(ipos);
	
	vec3 star_color = vec3(0.0);
	
	// Only render stars above a certain threshold for density control
	if (star_val > (1.0 - (star_density * 0.02))) {
		float twinkle = sin(TIME * twinkle_speed + star_val * 100.0) * 0.3 + 0.7;
		float brightness = pow(star_val, 30.0) * star_brightness * twinkle;
		
		// Color variation: mostly white, some slight blue/gray
		vec3 col = mix(vec3(1.0), vec3(0.9, 0.95, 1.0), hash(ipos + 1.0));
		star_color = col * brightness;
	}
	
	// 3. Middle Layer Stars (Fewer, slightly clearer)
	vec3 star_grid2 = dir * 120.0;
	vec3 ipos2 = floor(star_grid2);
	if (hash(ipos2) > 0.9992) {
		float twinkle2 = cos(TIME * (twinkle_speed * 0.5) + hash(ipos2) * 50.0) * 0.2 + 0.8;
		star_color += vec3(0.5) * star_brightness * twinkle2;
	}

	COLOR = final_bg + star_color;
}
