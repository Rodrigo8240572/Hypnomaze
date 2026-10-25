shader_type canvas_item;

uniform vec4 col_a : source_color = vec4(0.82, 0.78, 0.9, 1.0);
uniform vec4 col_b : source_color = vec4(0.12, 0.08, 0.16, 1.0);
uniform float speed = 0.55;
uniform float arms = 9.0;
uniform float reduce_flash = 0.0;
uniform float aspect = 1.777;
uniform float hole = 0.28;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= aspect;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float spin = mix(2.4, 0.7, reduce_flash);
	float rings = 0.5 + 0.5 * sin(r * 16.0 - TIME * spin * speed);
	float arms_wave = 0.5 + 0.5 * sin(a * arms + r * 4.0 - TIME * spin * speed * 0.35);
	float s = mix(rings, mix(rings, arms_wave, 0.35), 1.0 - reduce_flash);
	vec4 col = mix(col_b, col_a, s);
	float inner = smoothstep(hole - 0.04, hole + 0.02, r);
	float fade = 1.0 - smoothstep(1.35, 1.7, r);
	col.a = inner * fade;
	COLOR = col;
}
