shader_type spatial;

// Common Uniforms
uniform int planet_type = 0; // 0: Terrestrial, 1: Gas Giant, 2: Earth
uniform vec3 base_color : source_color = vec3(0.5);
uniform vec3 accent_color : source_color = vec3(0.3);
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.3;

// Noise function for surface detail
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * vec2(2.0, 1.0);
	float n = fbm(uv * 10.0 + TIME * 0.01);
	vec3 final_color;
	float roughness = 0.8;
	
	if (planet_type == 0) { // Terrestrial (Mars, Mercury, etc)
		final_color = mix(base_color, accent_color, n);
	} 
	else if (planet_type == 1) { // Gas Giant (Jupiter, Saturn)
		float bands = fbm(vec2(uv.y * 20.0, uv.x * 2.0 + n * 0.5));
		final_color = mix(base_color, accent_color, bands);
		roughness = 0.4;
	} 
	else if (planet_type == 2) { // Earth
		float ocean_land = fbm(uv * 8.0);
		if (ocean_land > 0.55) {
			final_color = mix(vec3(0.1, 0.4, 0.1), vec3(0.4, 0.3, 0.1), (ocean_land - 0.55) * 2.0); // Land
		} else {
			final_color = vec3(0.05, 0.15, 0.5); // Ocean
			roughness = 0.2;
		}
		
		// Clouds
		float clouds = fbm(uv * 15.0 + TIME * 0.05);
		if (clouds > 0.6) {
			final_color = mix(final_color, vec3(0.9), (clouds - 0.6) * cloud_opacity * 2.0);
		}
	}
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	
	// Fresnel Atmosphere
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	vec3 atmospheric_glow = base_color * 0.5;
	ALBEDO = mix(ALBEDO, atmospheric_glow, fresnel * 0.4);
	EMISSION = atmospheric_glow * fresnel * 0.2;
}
