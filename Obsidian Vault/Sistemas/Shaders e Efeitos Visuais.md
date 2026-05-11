# ✨ Shaders & Efeitos Visuais

#sistema #shader #visual #canvas-item

> Sistema de efeitos visuais via shaders GLSL rodando em CanvasLayer. Atualmente usado para o efeito de bolhas no [[Mapas/FendaDosPiratas]].

---

## Resumo

Efeitos visuais de tela inteira são implementados com shaders `canvas_item` aplicados a um `ColorRect` de tela cheia dentro de um `CanvasLayer`. Nenhuma lógica GDScript por frame é necessária — toda a animação roda na GPU.

---

## Arquitetura

```
CanvasLayer (layer = -1)
    └── ColorRect (anchors = tela inteira)
            └── ShaderMaterial
                    └── Bolhas.gdshader
```

### Por que `layer = -1`?
- Renderiza **acima** do mundo 3D
- Renderiza **abaixo** da HUD (que usa camadas positivas)
- Resultado: bolhas aparecem sobre o cenário mas atrás de menus e botões

### Por que `mouse_filter = 2` (IGNORE)?
- Sem isso, o ColorRect bloqueia todos os cliques do jogador
- `IGNORE` faz o nó ser completamente transparente a eventos de mouse

---

## Bolhas.gdshader

### Parâmetros Uniformes

| Uniform | Range | Padrão | Descrição |
|---------|-------|--------|-----------|
| `velocidade` | 0.02–0.25 | 0.065 | Velocidade de subida das bolhas |
| `opacidade` | 0.0–1.0 | 0.60 | Opacidade máxima das bolhas |
| `raio_max` | 0.005–0.07 | 0.030 | Raio máximo em coordenadas UV |

### Técnicas Usadas

**Hash Determinístico**
```glsl
float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }
```
Gera valores pseudo-aleatórios únicos por bolha (posição X, velocidade, tamanho, fase) sem precisar de texturas ou arrays.

**Correção de Aspect Ratio**
```glsl
float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
// Aplica ao eixo X das bolhas para que sejam circulares
vec2 uv_corrigido = vec2(uv.x * aspect, uv.y);
```

**Forma de Anel (Ring)**
```glsl
float outer = smoothstep(raio, raio - borda, dist);
float inner = smoothstep(raio * 0.7, raio * 0.7 - borda, dist);
float ring = outer - inner;  // Anel transparente no meio
```

**Highlight**
Ponto brilhante no canto superior-esquerdo de cada bolha, simulando reflexo de luz.

**Fade nas Bordas**
- Fade in quando bolha sobe da base (t=0→0.1)
- Fade out quando bolha chega ao topo (t=0.9→1.0)

### Número de Bolhas
22 bolhas independentes, computadas em loop dentro do `fragment()`. Cada uma tem fase, velocidade e raio únicos baseados no índice `float(i)`.

---

## bolhas_fundo.tscn

```
[node name="BolhasFundo" type="CanvasLayer"]
layer = -1

[node name="ColorRect" type="ColorRect" parent="."]
anchors_preset = 15      ← tela cheia
mouse_filter = 2         ← IGNORE (não bloqueia cliques)
color = Color(0,0,0,0)   ← fundo totalmente transparente
material = ShaderMaterial (Bolhas.gdshader)
```

---

## Como Adicionar a um Mapa

```gdscript
# fenda_dos_piratas.gd
const BolhasFundo = preload("res://Cenas Locais/bolhas_fundo.tscn")

func _ready():
    add_child(BolhasFundo.instantiate())
```

---

## Tuning Rápido

| Objetivo | Parâmetro a ajustar |
|----------|-------------------|
| Bolhas mais rápidas | ↑ `velocidade` |
| Bolhas maiores | ↑ `raio_max` |
| Efeito mais sutil | ↓ `opacidade` |
| Mais bolhas na tela | Aumentar o loop (atualmente 22) |

---

## Relações

- [[Mapas/FendaDosPiratas]] — único mapa que usa o efeito atualmente; add_child via `_ready()`
- [[Código/Bolhas.gdshader]] — implementação GLSL completa do shader
- [[Inimigos/HolandesVoador]] — o boss que habita o mapa onde o efeito está ativo; cria a atmosfera da luta
- [[Referência Rápida — Bugs e Soluções]] — documenta o bug do `ColorRect` bloqueando cliques (mouse_filter = 2)

---

## Tags

`#sistema` `#shader` `#visual` `#canvas-item` `#bolhas` `#glsl`
