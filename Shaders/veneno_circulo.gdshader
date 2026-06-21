shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform float velocidade : hint_range(0.1, 5.0) = 1.5;
uniform float num_aneis : hint_range(2.0, 12.0) = 5.0;
uniform vec3 cor_interna : source_color = vec3(0.02, 0.4, 0.06);
uniform vec3 cor_borda : source_color = vec3(0.2, 1.0, 0.25);
uniform float intensidade : hint_range(0.1, 4.0) = 1.2;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);

	if (dist > 1.0) {
		discard;
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

	// Pulso lento de toda a área
	float pulso = sin(TIME * 1.1) * 0.15 + 0.85;

	// Composição de cor
	vec3 cor = mix(cor_interna, cor_borda, anel * 0.55 + borda * 0.85);
	cor += cor_borda * runa * 0.45;

	float alpha = mask * pulso * (0.38 + anel * 0.28 + borda * 0.55 + runa * 0.22);
	alpha = clamp(alpha, 0.0, 0.92);

	ALBEDO = cor * intensidade;
	ALPHA = alpha;
}
