shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

uniform vec3 tile_color : source_color = vec3(0.42, 0.43, 0.45);
uniform vec3 grout_color : source_color = vec3(0.07, 0.075, 0.08);
uniform vec3 accent : source_color = vec3(0.38, 0.12, 0.55);
uniform float tile_m = 0.92;
uniform float grout = 0.028;
uniform float accent_mix : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;
varying vec3 world_n;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_n);
	vec2 wp;
	if (n.y > n.x && n.y > n.z) {
		wp = world_pos.xz;
	} else if (n.x > n.z) {
		wp = world_pos.zy;
	} else {
		wp = world_pos.xy;
	}
	vec2 uv = wp / tile_m;
	vec2 f = fract(uv);
	float line = max(step(1.0 - grout, f.x), step(1.0 - grout, f.y));
	line = max(line, max(step(f.x, grout * 0.45), step(f.y, grout * 0.45)));
	vec3 base = mix(tile_color, accent, accent_mix);
	float shade = 0.92 + 0.08 * fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5);
	ALBEDO = mix(base * shade, grout_color, line);
	ROUGHNESS = mix(0.38, 0.92, line);
	METALLIC = mix(0.08, 0.0, line);
	AO = mix(1.0, 0.45, line);
}
