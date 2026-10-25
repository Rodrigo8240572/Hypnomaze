shader_type spatial;
render_mode unshaded, specular_disabled, shadows_disabled, cull_disabled;

uniform vec3 glow_color : source_color = vec3(0.15, 1.0, 0.78);
uniform float energy = 8.5;

void fragment() {
	float pulse = 0.88 + 0.12 * sin(TIME * 2.1);
	vec3 col = glow_color * pulse;
	ALBEDO = col;
	EMISSION = col * energy;
}
