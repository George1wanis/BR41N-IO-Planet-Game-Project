shader_type spatial;
render_mode blend_add, cull_front, unshaded;

uniform vec4 atmosphere_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float outer_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float inner_intensity : hint_range(0.0, 10.0) = 0.5;
uniform float fresnel_power : hint_range(0.1, 10.0) = 4.0;

void fragment() {
    // Fresnel effect: dot product of normal and view direction
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
    
    // Combine intensities
    float alpha = fresnel * outer_intensity;
    
    ALBEDO = atmosphere_color.rgb;
    ALPHA = alpha;
}
