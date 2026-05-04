# 🏴‍☠️ Wiki do Jogo — Índice Principal

> Tower defense com ondas de inimigos, múltiplos mapas e sistema de progressão infinita.

---

## 🗺️ Navegação Rápida

### [[Sistemas/GameManager|🎮 GameManager]]
Núcleo global do jogo — ondas, multiplicadores, modo infinito.

### [[Sistemas/Ondas e Spawner|🌊 Ondas & Spawner]]
Geração procedural, filas de inimigos, ondas pré-definidas.

### [[Sistemas/InimigoBase|🧠 InimigoBase]]
Classe base de todos os inimigos — movimento, ataque, HP, navegação.

### [[Sistemas/Navegação e Movimento|🧭 Navegação & Movimento]]
NavigationAgent3D, pathfinding, bugs de travamento e soluções.

### [[Sistemas/TelaAvisoInimigo|⚠️ TelaAvisoInimigo]]
Aviso na primeira aparição de inimigo novo — pausa o jogo.

### [[Sistemas/Shaders e Efeitos Visuais|✨ Shaders & Efeitos Visuais]]
Efeito de bolhas, CanvasLayer, shaders canvas_item.

---

## 👾 Inimigos

| Nota | Tipo | HP | Habilidade |
|------|------|----|------------|
| [[Inimigos/HolandesVoador]] | BOSS | 1800 | Salto Fantasma (teleporte) |
| [[Inimigos/Categorias de Inimigos]] | — | — | Enum NORMAL / MINI_BOSS / BOSS |

---

## 🗺️ Mapas

| Nota | Tema | Especial |
|------|------|---------|
| [[Mapas/FendaDosPiratas]] | Piratas | Efeito bolhas, BarcoBase |

---

## 💻 Código

| Arquivo | Responsabilidade |
|---------|-----------------|
| [[Código/holandes_voador.gd]] | Boss Holandês Voador + Salto Fantasma |
| [[Código/inimigo_base.gd]] | Base class de todos os inimigos |
| [[Código/spawner_inimigos.gd]] | Spawner, ondas, modo infinito |
| [[Código/Bolhas.gdshader]] | Shader GLSL de bolhas animadas |

---

## 🔗 Grafo de Relações Principais

```
GameManager ──► Spawner ──► InimigoBase ──► HolandesVoador
     │               │              │
     ▼               ▼              ▼
  ondas       WaveData/Config   NavigationAgent3D
     │
     ▼
FendaDosPiratas ──► BolhasFundo ──► Bolhas.gdshader
```

---

## 🐛 Referência Rápida

### [[Referência Rápida — Bugs e Soluções|🐛 Bugs & Soluções]]
Todos os bugs documentados com causa raiz, solução e checklist para novos inimigos.

---

## 📌 Tags Globais

`#sistema` `#inimigo` `#mapa` `#codigo` `#bug-fix` `#boss` `#shader` `#navegacao`
