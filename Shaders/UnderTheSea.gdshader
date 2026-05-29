shader_type spatial;
render_mode blend_mix, depth_draw_opaque, unshaded, cull_disabled;

// =====================================================
// BOLHAS SUBINDO — GODOT 4.x (SPATIAL)
// Compatível com AMD / NVIDIA / Intel
// =====================================================

// Quantidade de bolhas
uniform int quantidade = 40;
// Velocidade geral
uniform float velocidade : hint_range(0.01, 1.0) = 0.08;
// Tamanho mínimo e máximo
uniform float tamanho_min : hint_range(0.002, 0.10) = 0.010;
uniform float tamanho_max : hint_range(0.002, 0.20) = 0.040;
// Transparência geral
uniform float opacidade : hint_range(0.0, 1.0) = 0.45;
// Intensidade do movimento sinuoso
uniform float sinuoso : hint_range(0.0, 0.20) = 0.035;

// Proporção UV do mesh (para manter as bolhas redondas dependendo da escala do mesh)
uniform float mesh_aspect = 1.0;

// =====================================================
// HASH ALEATÓRIO
// =====================================================

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453123);
}

// =====================================================
// CÍRCULO SUAVE
// =====================================================

float bubble_circle(vec2 uv, vec2 pos, float radius, float aspect) {

	vec2 diff = uv - pos;
// mantém bolhas circulares
	diff.x *= aspect;

	float dist = length(diff);

	return 1.0 - smoothstep(
		radius * 0.85,
		radius,
		dist
	);
}

// =====================================================
// FRAGMENT
// =====================================================

void fragment() {

	vec2 uv = UV;

	// Aspect ratio definido via uniform para adaptar ao formato do mesh
	float aspect = mesh_aspect;

	vec4 final_color = vec4(0.0);

	// =================================================
	// LOOP DAS BOLHAS
	// =================================================

	for (int i = 0; i < quantidade; i++) {

		float fi = float(i);
// ---------------------------------------------
		// Aleatórios
		// ---------------------------------------------

		float seed1 = hash(fi * 12.345);
		float seed2 = hash(fi * 45.678);
		float seed3 = hash(fi * 91.234);
		float seed4 = hash(fi * 27.891);
		float seed5 = hash(fi * 63.726);
// ---------------------------------------------
		// Tamanho aleatório
		// ---------------------------------------------

		float radius = mix(
			tamanho_min,
			tamanho_max,
			seed1
		);

		// ---------------------------------------------
		// Velocidade individual
		// ---------------------------------------------

		float vel =
			velocidade *
			mix(0.6, 1.4, seed2);
// ---------------------------------------------
		// Tempo da bolha
		// ---------------------------------------------

		float t =
			fract(TIME * vel + seed3);
// ---------------------------------------------
		// Movimento vertical
		// ---------------------------------------------

		float y =
			1.2 - (t * 1.4);
// ---------------------------------------------
		// Movimento sinuoso horizontal
		// ---------------------------------------------

		float freq =
			mix(1.0, 4.0, seed4);
		float wave =
			sin(
				t * freq * 6.28318 +
				seed5 * 10.0
			) * sinuoso;

		float x =
			seed2 + wave;
// wrap horizontal
		x = fract(x + 1.0);

		vec2 pos = vec2(x, y);

		// ---------------------------------------------
		// Bolha principal
		// ---------------------------------------------

		float bubble =
			bubble_circle(
				uv,
				pos,
				radius,
				aspect
			);
// ---------------------------------------------
		// Borda da bolha
		// ---------------------------------------------

		float border =
			bubble_circle(
				uv,
				pos,
				radius,
				aspect
			)
			-
			bubble_circle(
				uv,
				pos,
				radius * 0.72,
				aspect
			);
// ---------------------------------------------
		// Brilho/reflexo
		// ---------------------------------------------

		vec2 shine_pos =
			pos +
			vec2(
				-radius * 0.30,
				-radius * 0.30
			);

		float shine =
			bubble_circle(
				uv,
				shine_pos,
				radius * 0.18,
				aspect
			);
// ---------------------------------------------
		// Fade entrada/saída
		// ---------------------------------------------

		float fade_in =
			smoothstep(0.0, 0.08, t);

		float fade_out =
			smoothstep(0.0, 0.08, 1.0 - t);
		float fade =
			fade_in * fade_out;

		// ---------------------------------------------
		// Cor da bolha
		// ---------------------------------------------

		vec3 bubble_color =
			vec3(0.65, 0.90, 1.0);

		vec3 border_color =
			vec3(0.85, 0.97, 1.0);
// Interior
		final_color.rgb +=
			bubble_color *
			bubble *
			0.08 *
			fade;

		// Borda
		final_color.rgb +=
			border_color *
			border *
			0.9 *
			fade;

		// Brilho
		final_color.rgb +=
			vec3(1.0) *
			shine *
			0.8 *
			fade;
// Alpha
		final_color.a +=
			(border * 0.5 + bubble * 0.08) *
			fade *
			opacidade;
	}

	ALBEDO = clamp(final_color.rgb, 0.0, 1.0);
	ALPHA = clamp(final_color.a, 0.0, 1.0);
}