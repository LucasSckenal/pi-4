shader_type spatial;
render_mode depth_draw_always, unshaded;

uniform sampler2D albedo_texture : source_color; // Para manter as cores originais
uniform vec4 color_filter : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Obtém a cor original do objeto
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * color_filter.rgb;

	// Matriz de Bayer 4x4
	float bayer[16] = float[](
		0.0625, 0.5625, 0.1875, 0.6875,
		0.8125, 0.3125, 0.9375, 0.4375,
		0.25,   0.75,   0.125,  0.625,
		1.0,    0.5,    0.875,  0.375
	);

	// Determina a posição do pixel na tela para aplicar a matriz
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	float threshold = bayer[y * 4 + x];

	// Se o alpha solicitado for menor que o limite da matriz, descarta o pixel
	if (alpha_threshold < threshold) {
		discard;
	}
}