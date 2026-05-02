shader_type spatial;
render_mode cull_front, unshaded; // Renderiza apenas a parte de "dentro" invertida

uniform vec4 outline_color : source_color = vec4(0, 0, 0, 1);
uniform float outline_thickness = 0.05;

void vertex() {
    // Expande a malha na direção das normais
    VERTEX += NORMAL * outline_thickness;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}