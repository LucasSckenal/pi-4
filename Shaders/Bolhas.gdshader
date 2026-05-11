shader_type canvas_item;

// ==========================================
// BOLHAS SUBINDO — efeito de tela
// ==========================================

uniform float velocidade : hint_range(0.02, 0.25) = 0.065;
uniform float opacidade  : hint_range(0.0,  1.0)  = 0.60;
uniform float raio_max   : hint_range(0.005, 0.07) = 0.030;

// Hash pseudoaleatório determinístico
float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Correção de aspecto: garante bolhas circulares em qualquer resolução
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	vec4 cor = vec4(0.0);

	// 22 bolhas independentes — cada uma com vel/raio/fase únicas
	for (int i = 0; i < 22; i++) {
		float f = float(i);

		float vel    = velocidade * (0.50 + hash(f * 13.71));
		float raio   = raio_max   * (0.25 + hash(f *  7.31) * 0.75);
		float x_base = hash(f *  3.17);
		float fase   = hash(f *  5.73) * 6.2832;
		float wobble = 0.010 + hash(f *  9.31) * 0.016;
		float w_freq = 1.50  + hash(f * 11.13) * 3.50;
		float inicio = hash(f * 17.37);   // offset de fase para não subirem juntas

		// t: ciclo 0→1 (nasce em baixo, desaparece em cima)
		float t = mod(TIME * vel + inicio, 1.0);
		float y = 1.0 - t;
		float x = x_base + sin(t * w_freq * 6.2832 + fase) * wobble;

		vec2 centro = vec2(x, y);

		// Distância com aspecto corrigido
		vec2 diff  = uv - centro;
		diff.x    *= aspect;
		float dist = length(diff);

		// Fade: aparece gradualmente (t=0), desaparece no topo (t=1)
		float alpha = smoothstep(0.0, 0.12, t) * smoothstep(0.0, 0.08, 1.0 - t);

		// Anel da bolha (camada externa - interna)
		float outer = smoothstep(raio + 0.004, raio - 0.001, dist);
		float inner = smoothstep(raio * 0.72 + 0.003, raio * 0.72, dist);
		float anel  = outer - inner;

		// Reflexo/brilho no canto superior-esquerdo
		vec2 h_diff = uv - (centro + vec2(-raio * 0.38 / aspect, -raio * 0.38));
		h_diff.x   *= aspect;
		float shine = smoothstep(raio * 0.22, 0.0, length(h_diff));

		float ints = alpha * opacidade;

		// Anel azul-claro
		cor.rgb += vec3(0.50, 0.87, 1.00) * anel  * ints;
		cor.a   += anel  * ints * 0.85;

		// Brilho branco
		cor.rgb += vec3(0.95, 0.98, 1.00) * shine * ints * 0.45;
		cor.a   += shine * ints * 0.35;
	}

	COLOR = clamp(cor, vec4(0.0), vec4(1.0));
}
