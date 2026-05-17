shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

/// Cor base do olho (roxo cósmico por defeito)
uniform vec4 cor_olho : source_color = vec4(0.55, 0.0, 1.0, 1.0);
/// Multiplicador geral de brilho
uniform float intensidade : hint_range(0.0, 8.0) = 2.5;

// ═══════════════════════════════════════════════════════════════════════════
// FUNÇÕES DE RUÍDO — geram a textura orgânica da íris e da névoa
// ═══════════════════════════════════════════════════════════════════════════
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float smoothNoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i),           hash21(i + vec2(1, 0)), f.x),
	           mix(hash21(i + vec2(0,1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
// fBm de 3 oitavas — dá turbulência suave
float fbm(vec2 p) {
	return smoothNoise(p) * 0.5
	     + smoothNoise(p * 2.1) * 0.25
	     + smoothNoise(p * 4.5) * 0.125;
}

// ═══════════════════════════════════════════════════════════════════════════
// VERTEX — billboard esférico (olho sempre olha para a câmera)
// ═══════════════════════════════════════════════════════════════════════════
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(INV_VIEW_MATRIX[0].xyz), 0.0),
		vec4(normalize(INV_VIEW_MATRIX[1].xyz), 0.0),
		vec4(normalize(INV_VIEW_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]
	);
}

// ═══════════════════════════════════════════════════════════════════════════
// FRAGMENT — desenha a silhueta do olho + névoa cósmica
// ═══════════════════════════════════════════════════════════════════════════
void fragment() {
	// UV de -1..1 (centro = 0,0)
	vec2 uv = UV * 2.0 - 1.0;
	float t = TIME;

	// ── Distância elíptica (define a forma oval do olho) ──────────────────
	// semi-eixo X = 0.65, semi-eixo Y = 0.28  →  olho mais largo que alto
	vec2 ov = vec2(uv.x / 0.65, uv.y / 0.28);
	float ed = length(ov);

	// ── Fenda vertical (pupila cósmica tipo réptil) ───────────────────────
	// A fenda é mais larga no centro e afila em direção às pontas
	float slit_hw = 0.052 * max(1.0 - abs(uv.y) * 3.2, 0.08);
	float slit = smoothstep(slit_hw, 0.0, abs(uv.x))
	           * smoothstep(0.27, 0.0, abs(uv.y));

	// ── Íris (anel de energia perturbado por ruído) ───────────────────────
	float iris = smoothstep(0.95, 0.38, ed) * smoothstep(0.02, 0.28, ed);
	iris *= 0.60 + 0.40 * fbm(uv * 5.0 + t * 0.18);

	// ── Brilho central difuso ─────────────────────────────────────────────
	float glow = exp(-ed * ed * 2.6) * 1.6;

	// ── Neblina cósmica exterior (névoa que gira devagar) ─────────────────
	float r_pol = length(uv);                        // distância polar
	float ang   = atan(uv.y, uv.x);
	// ponto no espaço UV rodado pelo tempo → cria efeito de redemoinho
	vec2 sw = vec2(cos(ang + t * 0.055), sin(ang + t * 0.055)) * r_pol;
	float fog = fbm(sw * 2.1 + t * 0.07) * 0.58
	          + fbm(uv * 1.55 - vec2(t * 0.05, t * 0.065)) * 0.42;
	fog = clamp(fog, 0.0, 1.0);
	// Concentra no anel entre a borda do olho e a borda do quad
	fog *= smoothstep(1.55, 0.5, r_pol) * smoothstep(0.18, 0.52, r_pol);

	// ── Pulso de vida (respiração suave do olho) ──────────────────────────
	float pulso = 0.82 + 0.18 * sin(t * 1.3);

	// ── Composição de cores ───────────────────────────────────────────────
	vec3 c      = cor_olho.rgb;
	vec3 c_slit = mix(c, vec3(1.0, 0.85, 1.0), 0.55); // fenda: branco-lilás
	vec3 c_fog  = mix(c, vec3(0.07, 0.0, 0.22), 0.60); // névoa: roxo profundo

	vec3 cor  = c      * (iris * 2.3 + glow * 1.9) * intensidade * pulso;
	cor      += c_slit *  slit * 6.0               * intensidade * pulso;
	cor      += c_fog  *  fog  * 0.9               * intensidade;

	// ── Alpha (controla força do blend_add) ───────────────────────────────
	float eye_a = smoothstep(1.08, 0.48, ed);               // máscara do olho
	float fog_a = fog * 0.45 * smoothstep(1.6, 0.65, r_pol); // aura exterior
	float alpha = max(eye_a, fog_a);
	if (alpha < 0.004) discard;

	// modula pela intensidade luminosa do pixel
	alpha *= clamp(
		iris * 0.85 + slit * 1.5 + glow * 0.65 + fog * 0.28,
		0.0, 1.2
	) * pulso;

	ALBEDO = cor;
	ALPHA  = clamp(alpha, 0.0, 1.0);
}
