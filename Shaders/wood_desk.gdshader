shader_type canvas_item;

// Mesa de madeira procedural (tábuas horizontais com veio e juntas)
uniform vec3 cor_clara : source_color = vec3(0.40, 0.26, 0.14);
uniform vec3 cor_escura : source_color = vec3(0.22, 0.13, 0.06);
uniform float tabuas = 7.0;
uniform float veio = 34.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float row = floor(uv.y * tabuas);
	float offset = hash(vec2(row, 1.0)) * 10.0;          // cada tábua desloca o veio
	vec2 wuv = vec2(uv.x * 3.0 + offset, uv.y * tabuas);
	// veio alongado na horizontal
	float g = noise(vec2(wuv.x * veio, wuv.y * 2.0));
	g = mix(g, noise(vec2(wuv.x * veio * 0.5, wuv.y)), 0.5);
	vec3 col = mix(cor_escura, cor_clara, g);
	// juntas escuras entre as tábuas
	float py = fract(uv.y * tabuas);
	float junta = smoothstep(0.0, 0.05, py) * smoothstep(1.0, 0.95, py);
	col *= mix(0.45, 1.0, junta);
	// vinheta para profundidade
	float vig = smoothstep(1.15, 0.25, distance(uv, vec2(0.5)));
	col *= mix(0.65, 1.0, vig);
	COLOR = vec4(col, 1.0);
}
