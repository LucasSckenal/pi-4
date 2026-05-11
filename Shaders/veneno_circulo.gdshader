shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform float velocidade : hint_range(0.1, 5.0) = 1.5;
uniform float num_aneis : hint_range(2.0, 12.0) = 5.0;
uniform vec3 cor_interna : source_color = vec3(0.02, 0.4, 0.06);
uniform vec3 cor_borda : source_color = vec3(0.2, 1.0, 0.25);
uniform float intensidade : hint_range(0.1, 4.0) = 1.2;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);

	if (dist > 1.0) {
		ALPHA = 0.0;
		return;
	}

	// Borda suave
	float mask = smoothstep(1.0, 0.88, dist);

	// Anéis expandindo do centro para fora
	float anel = sin(dist * num_aneis * 3.14159 - TIME * velocidade);
	anel = anel * 0.5 + 0.5;

	// Glow intenso na borda do círculo
	float borda = pow(smoothstep(0.82, 1.0, dist), 2.0);

	// Padrão de runa com simetria hexagonal rotacionando
	float angulo = atan(uv.y, uv.x);
	float runa = sin(angulo * 6.0 + dist * 10.0 - TIME * 0.4);
	runa *= sin(angulo * 3.0 - dist * 7.0 + TIME * 0.65);
	runa = pow(max(runa, 0.0), 3.0);

	// Bolhas aparecendo e desaparecendo aleatoriamente
	vec2 bubble_uv = uv * 5.0;
	vec2 cell = floor(bubble_uv + TIME * 0.2);
	float seed = hash21(cell);
	float btime = fract(TIME * 0.55 + seed * 3.7);
	float bubble = smoothstep(0.0, 0.22, btime) * smoothstep(0.55, 0.3, btime);
	bubble *= step(0.72, seed) * mask;

	// Pulso lento de toda a área
	float pulso = sin(TIME * 1.1) * 0.15 + 0.85;

	// Composição de cor
	vec3 cor = mix(cor_interna, cor_borda, anel * 0.55 + borda * 0.85);
	cor += cor_borda * runa * 0.45;
	cor += vec3(0.35, 1.0, 0.1) * bubble * 0.9;

	float alpha = mask * pulso * (0.14 + anel * 0.22 + borda * 0.45 + runa * 0.18 + bubble * 0.35);

	ALBEDO = cor * intensidade;
	ALPHA = alpha;
}
