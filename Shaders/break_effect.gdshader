shader_type spatial;

// Garante que o material preserve a transparência corretamente sobre o objeto
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// Textura de ruído (Cellular) que define o formato das rachaduras
uniform sampler2D crack_noise : hint_default_black;

// Nível de dano (0.0 = intacto, 1.0 = destruído)
uniform float damage : hint_range(0.0, 1.0) = 0.0;

// Cor base das rachaduras
uniform vec4 crack_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);

void fragment() {
    float noise_val = texture(crack_noise, UV).r;
    
    // Inverte a lógica do ruído
    float crack_pattern = 1.0 - noise_val;
    
    // Calcula o limite de exibição baseado no dano atual
    float threshold = damage * 0.5;
    
    // Cria uma máscara dura (1.0 onde tem rachadura, 0.0 onde está intacto)
    float crack_mask = step(crack_pattern, threshold) * sign(damage);
    
    ALBEDO = crack_color.rgb;
    
    // Aplica a transparência: o shader só é renderizado onde a máscara indica rachadura
    ALPHA = crack_mask;
}