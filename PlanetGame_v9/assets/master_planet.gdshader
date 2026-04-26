shader_type spatial;

uniform int planet_type = 0; // 0: Rocky, 1: Gas, 2: Earth-like
uniform vec3 base_color : source_color = vec3(0.5);
uniform vec3 accent_color : source_color = vec3(0.3);
uniform float terrain_intensity : hint_range(0.0, 2.0) = 1.0;

// High-quality noise for terrain features
float hash(vec3 p) {
	p = fract(p * 0.3183099 + .1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// Use vertex position for 3D noise to avoid UV stretching at poles
	vec3 p = VERTEX * 2.0;
	float h = fbm(p + vec3(float(planet_type) * 10.0));
	
	vec3 color;
	float rough = 0.8;
	
	if (planet_type == 0) { // Rocky / Craters
		float crater_noise = pow(fbm(p * 4.0), 3.0);
		color = mix(base_color, accent_color, h);
		color = mix(color, vec3(0.1), crater_noise * 0.5); // "Craters"
		rough = 0.9;
	} 
	else if (planet_type == 1) { // Gas (Banded)
		float bands = noise(vec3(0.0, VERTEX.y * 15.0 + h * 0.5, 0.0));
		color = mix(base_color, accent_color, bands);
		rough = 0.4;
	}
	else if (planet_type == 2) { // Earth-like / Mountains
		if (h > 0.55) {
			// Land and mountains
			color = mix(vec3(0.2, 0.4, 0.1), vec3(0.4, 0.3, 0.2), (h - 0.55) * 2.0);
			if (h > 0.75) color = vec3(0.9); // Snow caps on mountains
		} else {
			color = vec3(0.05, 0.15, 0.4); // Deep Ocean
			rough = 0.2;
		}
		// Clouds
		float clouds = fbm(p * 0.5 + vec3(TIME * 0.02));
		if (clouds > 0.65) {
			color = mix(color, vec3(0.95), (clouds - 0.65) * 2.0);
			rough = 0.6;
		}
	}
	
	ALBEDO = color;
	ROUGHNESS = rough;
	
	// Subtle Atmospheric Glow
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 4.0);
	ALBEDO = mix(ALBEDO, base_color * 1.2, fresnel * 0.3);
	EMISSION = base_color * fresnel * 0.1;
}
