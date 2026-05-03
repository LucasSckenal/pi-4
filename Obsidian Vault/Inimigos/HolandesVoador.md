# 🏴‍☠️ Holandês Voador

#inimigo #boss #teleporte #salto-fantasma

> Boss pirata com habilidade de teleporte ao atingir 50% de HP. Herda de [[Sistemas/InimigoBase]].

---

## Resumo

O Holandês Voador é o boss principal do [[Mapas/FendaDosPiratas]]. Ele tem HP muito alto e velocidade lenta, compensada pela habilidade **Salto Fantasma**: ao ser reduzido a 50% de vida, desaparece com efeito de fumaça e reaparece em um spawner diferente do mapa, forçando o jogador a cobrir múltiplas frentes.

---

## Stats

| Stat | Valor |
|------|-------|
| Tipo | `BOSS` (Categoria = 2) |
| HP | 1800 |
| Velocidade | 0.45 (LENTA) |
| Dano por ataque | 35 |
| Distância de ataque | 2.5 |
| Recarga de ataque | 2.0s |
| Raio visão construções | 8.0 |
| Raio visão aliados | 6.0 |

---

## Habilidade: Salto Fantasma

### Parâmetros

| Parâmetro | Valor padrão | Descrição |
|-----------|-------------|-----------|
| `hp_gatilho_teleporte` | 0.5 | % de HP que ativa (50%) |
| `duracao_preparacao` | 1.2s | Fase de fade + fumaça antes de sumir |
| `duracao_imunidade_pos_teleporte` | 1.0s | Imunidade de ataque após reaparecer |
| `alpha_preparacao` | 0.3 | Transparência durante preparação |

### Fluxo da Habilidade

```
receber_dano() → vida_atual/vida_maxima <= 0.5
        │
        ▼
_salto_fantasma()
  ├── has_teleported = true  (trava: só pode ativar 1 vez)
  ├── is_teleporting = true  (bloqueia movimento)
  │
  ├── [1] Para completamente: velocity = Vector3.ZERO
  ├── [2] Emite sinal start_teleport_effect(pos)
  ├── [3] Fade do modelo para alpha_preparacao (0.3) em 0.72s
  ├── [4] await duracao_preparacao (1.2s)
  │
  ├── [5] Verifica se morreu durante preparação → aborta se sim
  │
  ├── [6] Emite sinal teleport_disappear
  ├── [7] modelo_3d.visible = false
  ├── [8] _selecionar_novo_caminho() → novo spawner
  │
  ├── (se nenhum caminho válido) → aborta sem punição, restaura visibilidade
  │
  ├── [9] global_position = novo_pos
  ├── [10] await process_frame  (NavigationAgent registra nova posição)
  │
  ├── [11] Fade in do modelo (alpha 0.3 → 1.0 em 0.4s)
  ├── [12] Emite sinal teleport_reappear(pos)
  │
  ├── [13] pode_atacar = false  (imunidade)
  ├── [14] await duracao_imunidade_pos_teleporte (1.0s)
  └── [15] pode_atacar = true, is_teleporting = false
```

### Seleção de Novo Caminho

```gdscript
func _selecionar_novo_caminho() -> Vector3:
    var spawners = get_tree().get_nodes_in_group("Spawner")
    # Exclui: caminho atual (current_path) + caminho de origem (initial_path)
    # Retorna posição aleatória de candidatos restantes
    # Retorna Vector3.ZERO se nenhum candidato válido
```

**Variáveis rastreadas:**
- `initial_path` — posição do spawner original (definida no `_ready()`)
- `current_path` — posição do spawner atual (atualizada após cada teleporte)

---

## Sinais Emitidos

```gdscript
signal start_teleport_effect(pos: Vector3)  # início da preparação
signal teleport_disappear                    # momento que some
signal teleport_reappear(pos: Vector3)       # momento que reaparece
```

Esses sinais são usados para conectar efeitos visuais/sonoros externos (partículas, fumaça, flash).

---

## Comportamento em `_physics_process`

Durante `is_teleporting = true`:
- Apenas gravidade aplicada (sem movimento horizontal)
- Ignora `super._physics_process`

Fora do teleporte:
- Chama `super._physics_process(delta)` normalmente
- **Fallback anti-travamento** inline: se boss está longe do alvo mas sem velocidade horizontal, aplica direção direta + `move_and_slide()` imediato

---

## `_ready()` — Setup Especial

```gdscript
func _ready() -> void:
    super._ready()
    await get_tree().process_frame  # aguarda spawner definir global_position
    initial_path = global_position
    current_path = global_position
    posicao_de_spawn = global_position  # evita teleporte para origem se cair
    
    alvo_atual = procurar_novo_alvo()
    if alvo_atual and nav_agent:
        # Encaixa no navmesh se necessário
        nav_agent.target_position = alvo_atual.global_position  # pré-aquece
```

---

## ⚠️ Bugs Conhecidos & Correções

| Bug | Causa | Solução |
|-----|-------|---------|
| Boss parado ao spawnar | `velocity` setada após `move_and_slide()` no super | Segundo `move_and_slide()` inline no fallback |
| Boss teleporta para origin | `posicao_de_spawn = Vector3.ZERO` | Setar `posicao_de_spawn = global_position` no `_ready()` |
| `vel` type error | `GameManager.multiplicador_velocidade_inimigo` sem tipo | Usar `as float` explicitamente |
| Nav não funciona após spawn | `is_navigation_finished()` = true no 1º frame | Pré-aquecer `nav_agent.target_position` no `_ready()` |

Ver também: [[Sistemas/Navegação e Movimento]]

---

## Arquivos

- [[Código/holandes_voador.gd]] — script completo
- `.tscn` em `Enemys/holandes_voador.tscn`
- Modelo 3D: `Enemys/holandes_voador.glb`
- Efeito visual do mapa: [[Código/Bolhas.gdshader]] — atmosfera subaquática durante a luta

---

## Relações

- [[Código/holandes_voador.gd]] — implementação completa deste boss
- [[Sistemas/InimigoBase]] — classe pai; herda navegação, ataque e HP
- [[Código/inimigo_base.gd]] — código da classe base; `procurar_novo_alvo()` com fallback "Base"
- [[Sistemas/Ondas e Spawner]] — spawna o boss e define `global_position` pós `add_child`
- [[Código/spawner_inimigos.gd]] — código que instancia este boss e seta sua posição
- [[Sistemas/GameManager]] — `multiplicador_velocidade_inimigo` lido em `_physics_process` (requer `as float`)
- [[Sistemas/Navegação e Movimento]] — documenta todos os bugs de movimento específicos deste boss
- [[Sistemas/TelaAvisoInimigo]] — exibe a dica de teleporte na primeira aparição
- [[Mapas/FendaDosPiratas]] — único mapa onde este boss aparece; tem 3+ spawners para teleporte
- [[Inimigos/Categorias de Inimigos]] — é do tipo `BOSS` (Categoria = 2)
- [[Referência Rápida — Bugs e Soluções]] — centralizador de todos os bugs corrigidos neste boss

---

## Tags

`#inimigo` `#boss` `#teleporte` `#salto-fantasma` `#fenda-dos-piratas`
