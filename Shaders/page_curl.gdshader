shader_type canvas_item;
render_mode blend_mix;

// Page-curl: a página (TEXTURE = snapshot) enrola a partir de uma borda,
// revelando transparência (a nova página fica por baixo).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float curl_radius : hint_range(0.02, 0.5) = 0.16;
uniform float flip_x = 0.0;   // 1.0 = enrola pelo lado oposto (página anterior)

void fragment() {
	vec2 uv = UV;
	float x = (flip_x > 0.5) ? (1.0 - uv.x) : uv.x;
	float origin = mix(1.0 + curl_radius, -curl_radius, progress);
	float d = x - origin;
	float arc = PI * curl_radius;
	vec4 outc = vec4(0.0);

	if (d < 0.0) {
		// ainda plano (não alcançado pela curva) → página normal
		float sx = (flip_x > 0.5) ? (1.0 - x) : x;
		outc = texture(TEXTURE, vec2(sx, uv.y));
	} else if (d <= arc) {
		// sobre o cilindro que enrola
		float theta = d / curl_radius;                 // 0..PI
		float curled = origin + curl_radius * sin(theta);
		if (curled >= 0.0 && curled <= 1.0) {
			float sx = (flip_x > 0.5) ? (1.0 - curled) : curled;
			vec4 c = texture(TEXTURE, vec2(sx, uv.y));
			float shade = 0.5 + 0.5 * cos(theta);      // dorso da página mais escuro
			outc = vec4(c.rgb * (0.45 + 0.55 * shade), c.a);
		}
	}
	// d > arc → transparente (revela a página de baixo)
	COLOR = outc;
}
