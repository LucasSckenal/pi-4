shader_type canvas_item;

uniform vec2 center;    // Centro em UV (0.0 a 1.0)
uniform float radius;   // Raio do círculo
uniform float feather;  // Suavidade da borda

void fragment() {
	vec2 uv = UV;
	
	// CORREÇÃO DAS LATERAIS:
	// Obtemos a proporção da tela (largura / altura)
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	// Ajustamos o eixo X tanto no UV atual quanto no centro para manter a circularidade
	vec2 adjusted_uv = vec2(uv.x, uv.y / aspect);
	vec2 adjusted_center = vec2(center.x, center.y / aspect);
	
	float dist = distance(adjusted_uv, adjusted_center);
	float alpha = smoothstep(radius, radius + feather, dist);
	
	COLOR = vec4(COLOR.rgb, COLOR.a * alpha);
}