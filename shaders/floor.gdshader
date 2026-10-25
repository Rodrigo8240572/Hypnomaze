shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

uniform vec3 color_a : source_color = vec3(0.055, 0.06, 0.065);
uniform vec3 color_b : source_color = vec3(0.09, 0.095, 0.1);
uniform float tile_m = 1.35;
uniform float cell = 5.4;
uniform vec3 neon : source_color = vec3(0.18, 1.0, 0.8);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / tile_m;
	vec2 f = fract(uv);
	float grout = max(step(0.97, f.x), step(0.97, f.y));
	grout = max(grout, max(step(f.x, 0.03), step(f.y, 0.03)));
	float check = step(0.5, fract((floor(uv.x) + floor(uv.y)) * 0.5));
	vec3 base = mix(color_a, color_b, check * 0.45);
	ALBEDO = mix(base, vec3(0.02, 0.022, 0.025), grout);
	ROUGHNESS = mix(0.18, 0.7, grout);
	METALLIC = mix(0.55, 0.05, grout);
	SPECULAR = 0.7;
	vec2 cell_uv = world_pos.xz / cell;
	vec2 d = min(fract(cell_uv), 1.0 - fract(cell_uv));
	float edge = 1.0 - smoothstep(0.006, 0.018, min(d.x, d.y));
	EMISSION = neon * edge * 5.5;
}
