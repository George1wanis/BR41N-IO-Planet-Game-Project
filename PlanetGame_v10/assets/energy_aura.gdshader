shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec3 aura_color : source_color = vec3(0.0, 1.0, 0.2);
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float rim_power : hint_range(0.1, 5.0) = 2.0;

void fragment() {
	// Fresnel effect for the "rim" look
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), rim_power);
	
	// Pulsing intensity
	float pulse = (sin(TIME * pulse_speed) * 0.2) + 0.8;
	
	ALPHA = fresnel * pulse * 0.6;
	ALBEDO = aura_color;
}
