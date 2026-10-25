shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float aberration : hint_range(0.0, 0.02) = 0.0025;
uniform float tint_amt : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.75, 0.12, 0.48);
uniform float vignette : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float a = aberration * (0.4 + length(c) * 1.6);
	float r = texture(screen_tex, uv + vec2(a, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(a, 0.0)).b;
	vec3 col = vec3(r, g, b);
	col = mix(col, col * tint * 1.35, tint_amt);
	float vig = 1.0 - vignette * smoothstep(0.35, 0.95, length(c) * 1.45);
	COLOR = vec4(col * vig, 1.0);
}
