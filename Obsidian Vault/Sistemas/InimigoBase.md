# 🧠 InimigoBase

#sistema #inimigo #classe-base #navegacao

> Classe base (`extends CharacterBody3D`) herdada por todos os inimigos. Centraliza movimento, ataque, dano, navegação e detecção de alvo.

---

## Resumo

`InimigoBase` é a espinha dorsal de todo inimigo do jogo. Ela gerencia:
- **Navegação** via `NavigationAgent3D`
- **Ataque** via `Area3D` (SensorAtaque)
- **HP e morte** com sinal de recompensa
- **Fallback de travamento** quando o nav-agent falha
- **Busca de alvo** entre construções e base principal

Todos os inimigos herdam essa classe. O [[Inimigos/HolandesVoador]] é o único que sobrescreve `_physics_process` e `receber_dano` com lógica adicional.

---

## Categoria (Enum)

```gdscript
enum Categoria {
    NORMAL,
    MINI_BOSS,
    BOSS
}
```

Usado pelo [[Sistemas/Ondas e Spawner]] para separar boss de normais no pool procedural.

---

## Propriedades Exportadas

### Identidade
| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `tipo_inimigo` | `Categoria` | NORMAL / MINI_BOSS / BOSS |
| `nome_inimigo` | `String` | Nome exibido na UI |
| `dica_tutorial` | `String` | Texto exibido na [[Sistemas/TelaAvisoInimigo]] |
| `status_velocidade` | `String` | Ex: "LENTA", "RÁPIDA" |
| `status_vida` | `String` | Ex: "ALTA", "MUITO ALTA" |

### Combate
| Propriedade | Tipo | Padrão |
|-------------|------|--------|
| `vida_maxima` | `int` | — |
| `velocidade` | `float` | — |
| `forca_dano` | `int` | — |
| `distancia_ataque` | `float` | — |
| `tempo_recarga_ataque` | `float` | — |

### Visão
| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `raio_visao_construcao` | `float` | Raio para detectar construções |
| `raio_visao_aliados` | `float` | Raio para detectar aliados |

---

## Variáveis de Estado

```gdscript
var vida_atual: int
var alvo_atual: Node3D
var pode_atacar: bool = true
var esta_morto: bool = false
var posicao_de_spawn: Vector3  # ⚠️ Deve ser setado após add_child
```

---

## Referências de Nós

```gdscript
@export var modelo_3d: Node3D
var nav_agent: NavigationAgent3D
```

---

## Funções Principais

### `procurar_novo_alvo() → Node3D`
Hierarquia de busca:
1. Construções no grupo `"construcoes"` dentro do `raio_visao_construcao`
2. `get_first_node_in_group("Castelo")` como fallback
3. `get_first_node_in_group("Base")` como fallback adicional *(fix fenda_dos_piratas)*

```gdscript
var base_principal = get_tree().get_first_node_in_group("Castelo")
if not base_principal:
    base_principal = get_tree().get_first_node_in_group("Base")
return base_principal
```

> 📌 O [[Mapas/FendaDosPiratas]] usa `BarcoBase.tscn` no grupo `"Base"`, não `"Castelo"`. Sem o fallback, o inimigo não encontraria alvo.

### `receber_dano(qtd: int, origem: String)`
- Reduz `vida_atual`
- Verifica morte (`vida_atual <= 0`)
- O [[Inimigos/HolandesVoador]] sobrescreve para verificar o gatilho do teleporte

### `_physics_process(delta)`
1. Aplica gravidade se no ar
2. Atualiza `nav_agent.target_position`
3. Calcula direção do `NavigationAgent3D`
4. Aplica velocidade + `move_and_slide()`

---

## Grupos

```gdscript
add_to_group("inimigos")  # usado por _esperar_limpeza() no spawner
```

---

## ⚠️ Armadilhas de Navegação

Ver nota dedicada: [[Sistemas/Navegação e Movimento]]

- `is_navigation_finished()` retorna `true` no primeiro frame → inimigo não se move
- `posicao_de_spawn` é `Vector3.ZERO` por padrão → se cair abaixo do `limite_queda_y`, teleporta para a origem
- `move_and_slide()` já é chamado dentro do `_physics_process` → velocity setada **depois** só é aplicada no próximo frame

---

## Relações

- [[Código/inimigo_base.gd]] — implementação completa desta classe
- [[Inimigos/HolandesVoador]] — herda e estende com Salto Fantasma
- [[Código/holandes_voador.gd]] — exemplo de subclasse com `_physics_process` sobrescrito
- [[Inimigos/Categorias de Inimigos]] — define e usa o enum `Categoria`
- [[Sistemas/Ondas e Spawner]] — instancia e posiciona os inimigos
- [[Código/spawner_inimigos.gd]] — seta `global_position` após `add_child`, causando o bug de spawn
- [[Sistemas/GameManager]] — lê `multiplicador_velocidade_inimigo`
- [[Sistemas/TelaAvisoInimigo]] — consome `dica_tutorial`, `nome_inimigo` e `tipo_inimigo`
- [[Sistemas/Navegação e Movimento]] — usa `NavigationAgent3D`; documenta todos os bugs desta classe
- [[Mapas/FendaDosPiratas]] — motivou o fallback do grupo `"Base"` em `procurar_novo_alvo()`
- [[Referência Rápida — Bugs e Soluções]] — lista todos os bugs da classe base

---

## Tags

`#sistema` `#classe-base` `#inimigo` `#navegacao` `#combate`
