shader_type spatial;

uniform vec3 ocean_color : source_color = vec3(0.05, 0.2, 0.5);
uniform vec3 land_color : source_color = vec3(0.1, 0.6, 0.2);

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

void fragment() {
	// Map spherical UVs to noise for procedural continents
	vec2 uv = UV * vec2(12.0, 6.0);
	float n = noise(uv) + 0.5 * noise(uv * 2.1) + 0.25 * noise(uv * 4.3);
	
	// Threshold for land vs ocean
	if (n > 0.8) {
		ALBEDO = land_color;
		ROUGHNESS = 0.8;
	} else {
		ALBEDO = ocean_color;
		ROUGHNESS = 0.2; // Shiny oceans
		SPECULAR = 0.5;
	}
	
	// Add a subtle atmospheric fresnel/glow
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	ALBEDO = mix(ALBEDO, vec3(0.4, 0.7, 1.0), fresnel * 0.4);
	
	// Slight rim lighting
	EMISSION = vec3(0.1, 0.2, 0.4) * fresnel * 0.5;
}
