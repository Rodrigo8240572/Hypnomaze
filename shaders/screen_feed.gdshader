shader_type spatial;
render_mode unshaded, cull_disabled, specular_disabled;

uniform float heat : hint_range(0.0, 1.0) = 0.45;
uniform int style = 0;

float sd_ellipse(vec2 p, vec2 r) {
	return length(p / r) - 1.0;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * 2.0 - 1.0;
	float t = TIME;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float rings = 0.5 + 0.5 * sin(r * 22.0 - t * (1.4 + heat));
	vec3 dark = vec3(0.05, 0.01, 0.07);
	vec3 mag = vec3(0.78, 0.14, 0.58);
	vec3 cyan = vec3(0.18, 0.95, 0.78);
	vec3 col = mix(dark, mix(mag, cyan, float(style % 2)), rings * 0.5);

	float head = sd_ellipse(p - vec2(0.0, 0.42 + 0.02 * sin(t * 1.3)), vec2(0.16, 0.20));
	float torso = sd_ellipse(p - vec2(0.0, 0.02), vec2(0.28, 0.38));
	float hips = sd_ellipse(p - vec2(0.03 * sin(t * 0.8), -0.42), vec2(0.36, 0.28));
	float body = min(min(head, torso), hips);
	float skin = smoothstep(0.05, -0.01, body);
	vec3 flesh = vec3(0.62, 0.34, 0.36);
	flesh += vec3(0.2, 0.04, 0.08) * (0.5 + 0.5 * sin(t * 2.2 + p.y * 8.0));
	col = mix(col, flesh, skin * (0.7 + heat * 0.25));

	float scan = 0.07 * sin(uv.y * 240.0 + t * 11.0);
	col += scan * vec3(0.45, 0.12, 0.5);
	col *= smoothstep(1.25, 0.15, r);
	ALBEDO = col;
	EMISSION = col * (1.4 + heat * 1.6);
}
