# 🌊 Ondas & Spawner

#sistema #spawner #ondas #procedural

> Sistema de geração e gestão de ondas de inimigos. Suporta ondas pré-definidas (`WaveData`) e modo infinito procedural.

---

## Resumo

Cada spawner no mapa é uma instância de `spawner_inimigos.gd`. Eles são independentes — cada um tem sua própria fila de inimigos e avisa o [[Sistemas/GameManager]] quando terminou. O sistema suporta dois modos:

1. **Ondas pré-definidas** — arrays de `WaveData` configuradas no editor
2. **Modo infinito** — geração procedural baseada em pool de inimigos das ondas normais

---

## Classes de Dados

### `WaveData` (Resource)
```gdscript
var nome_da_onda: String
var intervalo: float          # segundos entre spawns
var inimigos: Array[InimigoConfig]
```

### `InimigoConfig` (Resource)
```gdscript
var cena: PackedScene         # cena do inimigo
var quantidade: int
var icone: Texture2D
var cor: Color
```

---

## Fluxo de Spawn

```
GameManager.noite_iniciada
        │
        ▼
_iniciar_noite(n)
  ├── busca WaveData da onda atual
  ├── calcula hp_mult_base (modo infinito)
  ├── monta fila_inimigos[] + fila_hp_mult[]
  └── inicia TimerSpawn

TimerSpawn.timeout → _spawnar_proximo()
  ├── pop_front() da fila
  ├── instantiate() da cena
  ├── aplica vida_maxima * hp_mult ANTES de add_child
  ├── add_child(inimigo) na cena atual
  └── inimigo.global_position = spawner.global_position

Fila vazia → _esperar_limpeza()
  └── while grupo "inimigos" > 0: aguarda 1s
        │
        ▼
  _finalizar_onda()
  └── GameManager.registrar_spawner_concluido()
```

---

## Modo Infinito — Pool Procedural

### Construção do Pool (`_construir_pool_procedural`)
- Percorre todas as ondas pré-definidas
- Classifica inimigos em `pool_normais[]` ou `cena_boss`
- Detecção de boss: instancia temporariamente e verifica `tipo_inimigo`

```gdscript
var eh_boss = (instancia.tipo_inimigo == InimigoBase.Categoria.BOSS
            or instancia.tipo_inimigo == InimigoBase.Categoria.MINI_BOSS)
instancia.free()  # descarta imediatamente
```

### Geração Procedural (`_gerar_onda_procedural`)
- **Seed determinística**: `hash(str(onda_global) + "_" + name)` → mesmos 3 spawners geram ondas coerentes
- **Quantidade por spawner**: `clamp(3 + floor(onda / 4), 3, 8)`
- **Ondas de boss**: a cada 5 ondas (`onda % 5 == 0`), apenas o spawner `spawners[0]` spawna o boss
- **Escala de HP**: `1.0 + max(0, onda - 5) * 0.15` (linear a partir da onda 6)

---

## Grupo "Spawner"

Todos os spawners se adicionam ao grupo `"Spawner"` no `_ready()`.

```gdscript
add_to_group("Spawner")
```

O [[Inimigos/HolandesVoador]] usa esse grupo para selecionar o destino do teleporte:

```gdscript
var spawners: Array = get_tree().get_nodes_in_group("Spawner")
```

---

## Propriedades Exportadas

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `ondas` | `Array[WaveData]` | Ondas pré-definidas |
| `label_wave` | `Label` | UI para exibir número da onda |

---

## Relações

- [[Sistemas/GameManager]] — escuta `noite_iniciada`, chama `registrar_spawner_concluido`
- [[Código/spawner_inimigos.gd]] — implementação completa deste sistema
- [[Sistemas/InimigoBase]] — instancia e configura os inimigos
- [[Código/inimigo_base.gd]] — classe dos inimigos instanciados; `_ready()` recebe `global_position` pós `add_child`
- [[Inimigos/HolandesVoador]] — usa grupo "Spawner" para teleporte (Salto Fantasma)
- [[Código/holandes_voador.gd]] — usa `await process_frame` porque o spawner define `global_position` após `add_child`
- [[Mapas/FendaDosPiratas]] — contém múltiplos spawners; spawner[0] é o único a spawnar boss
- [[Inimigos/Categorias de Inimigos]] — distingue BOSS de NORMAL para pool procedural
- [[Sistemas/Navegação e Movimento]] — spawner fora do navmesh causa falha de pathfinding
- [[Referência Rápida — Bugs e Soluções]] — bug "inimigo parado ao spawnar" tem raiz no timing do spawner

---

## Tags

`#sistema` `#spawner` `#ondas` `#procedural` `#infinito`
