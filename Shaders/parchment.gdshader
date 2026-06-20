shader_type canvas_item;

// Pergaminho envelhecido: base creme, manchas suaves, vinheta nas bordas,
// fibras leves e uma moldura interna (linha dupla) estilo manuscrito.
uniform vec3 base : source_color = vec3(0.88, 0.80, 0.60);
uniform vec3 borda : source_color = vec3(0.60, 0.47, 0.28);

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

	// manchas (várias frequências)
	float n = noise(uv * 5.0) * 0.55 + noise(uv * 17.0) * 0.30 + noise(uv * 41.0) * 0.15;
	vec3 col = mix(base, base * 0.88, n);

	// fibras horizontais bem sutis
	float fib = noise(vec2(uv.x * 220.0, uv.y * 7.0));
	col *= mix(0.975, 1.0, fib);

	// vinheta: escurece/avermelha as bordas
	float dedge = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0;
	float vig = smoothstep(0.55, 1.0, clamp(dedge, 0.0, 1.0));
	col = mix(col, borda, vig * 0.5);

	// moldura interna (linha dupla)
	float m = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float l1 = smoothstep(0.014, 0.016, m) * (1.0 - smoothstep(0.018, 0.020, m));
	float l2 = smoothstep(0.024, 0.026, m) * (1.0 - smoothstep(0.028, 0.030, m));
	col = mix(col, borda * 0.7, max(l1, l2 * 0.6));

	COLOR = vec4(col, 1.0);
}
