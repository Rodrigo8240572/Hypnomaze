shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.7;
uniform float reduce_flash = 0.0;
uniform vec4 tint : source_color = vec4(0.85, 0.08, 0.42, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * 2.0 - 1.0;
	float t = TIME;
	float flash = mix(0.55 + 0.45 * sin(t * 9.0), 0.7, reduce_flash);
	float grid = abs(sin(uv.x * 40.0 + t)) * abs(sin(uv.y * 22.0));
	float vig = smoothstep(1.4, 0.2, length(p));
	vec3 col = tint.rgb * flash * (0.35 + grid * 0.5);
	float r = length(p - vec2(-0.15, 0.1));
	float body = smoothstep(0.55, 0.2, r);
	col = mix(col, vec3(0.55, 0.22, 0.28) * flash, body * 0.55);
	col += vec3(0.2, 0.0, 0.15) * (0.5 + 0.5 * sin(uv.y * 80.0 + t * 6.0));
	COLOR = vec4(col, (0.42 + intensity * 0.35) * vig);
}
