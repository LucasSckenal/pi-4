# 💻 Bolhas.gdshader

#codigo #shader #glsl #visual

> Shader GLSL que gera 22 bolhas animadas subindo pela tela. Usado no [[Mapas/FendaDosPiratas]].

**Caminho:** `Shaders/Bolhas.gdshader`

---

## Tipo de Shader

```glsl
shader_type canvas_item;
```

Roda sobre um `ColorRect` de tela cheia dentro de um `CanvasLayer`. Ver [[Sistemas/Shaders e Efeitos Visuais]] para arquitetura completa.

---

## Uniforms

```glsl
uniform float velocidade : hint_range(0.02, 0.25) = 0.065;
uniform float opacidade  : hint_range(0.0,  1.0)  = 0.60;
uniform float raio_max   : hint_range(0.005, 0.07) = 0.030;
```

Controláveis pelo `ShaderMaterial` no editor ou via GDScript:
```gdscript
material.set_shader_parameter("velocidade", 0.1)
```

---

## Técnicas Implementadas

### Hash Determinístico
```glsl
float hash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}
```
Gera um valor único `[0, 1)` para qualquer índice `n`. Usado para definir propriedades únicas de cada bolha sem arrays ou texturas.

### Por Bolha (loop de 22 iterações)
```glsl
for (int i = 0; i < 22; i++) {
    float fi = float(i);
    float x  = hash(fi * 1.3);                    // posição X fixa
    float vel = velocidade * (0.5 + hash(fi*2.7)); // velocidade única
    float raio = raio_max * (0.4 + hash(fi*3.1)); // tamanho único
    float fase = hash(fi * 5.9);                   // fase inicial única
    
    float t = fract(TIME * vel + fase);            // posição Y [0,1] em loop
    vec2 centro = vec2(x, 1.0 - t);               // sobe de baixo para cima
    ...
}
```

### Correção de Aspect Ratio
```glsl
float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
vec2 delta = uv - centro;
delta.x *= aspect;  // bolha fica circular, não oval
float dist = length(delta);
```

### Forma de Anel
```glsl
float borda = 0.002;
float outer = smoothstep(raio, raio - borda, dist);
float inner = smoothstep(raio * 0.7, raio * 0.7 - borda, dist);
float ring = outer - inner;  // área entre raio_externo e raio_interno
```

### Highlight (reflexo)
```glsl
vec2 highlight_pos = centro + vec2(-raio * 0.4 / aspect, -raio * 0.4);
float highlight = smoothstep(raio * 0.25, 0.0, length(uv - highlight_pos));
float brilho = highlight * 0.6;
```

### Fade nas Bordas
```glsl
float fade = smoothstep(0.0, 0.1, t) * smoothstep(1.0, 0.9, t);
// fade in nos primeiros 10%, fade out nos últimos 10%
float alpha = (ring + brilho) * opacidade * fade;
```

---

## Valores de Referência

| Parâmetro | Sutil | Padrão | Intenso |
|-----------|-------|--------|---------|
| `velocidade` | 0.03 | 0.065 | 0.15 |
| `opacidade` | 0.3 | 0.60 | 0.9 |
| `raio_max` | 0.015 | 0.030 | 0.06 |

---

## Performance

- 22 bolhas × `fragment()` por pixel de tela cheia
- Apenas operações matemáticas (sem amostras de textura)
- Muito leve — adequado para dispositivos móveis
- Para mais bolhas: aumentar o loop para 30–40 sem problema

---

## Relações

- [[Sistemas/Shaders e Efeitos Visuais]] — arquitetura completa do sistema CanvasLayer
- [[Mapas/FendaDosPiratas]] — único mapa usando este shader; instanciado via `bolhas_fundo.tscn`
- [[Inimigos/HolandesVoador]] — o boss que habita o mapa onde este efeito está ativo; atmosfera da luta
- [[Referência Rápida — Bugs e Soluções]] — bug `mouse_filter` esquecido no ColorRect bloqueia cliques
- [[Index]] — referência no índice principal do vault

---

## Tags

`#codigo` `#shader` `#glsl` `#visual` `#canvas-item` `#bolhas`
