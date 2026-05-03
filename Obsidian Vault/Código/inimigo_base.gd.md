# 💻 inimigo_base.gd

#codigo #classe-base #gdscript #navegacao

> Classe base de todos os inimigos. Define todo o comportamento padrão de movimento, ataque, HP e navegação.

**Caminho:** `Enemys/inimigo_base.gd`

---

## Estrutura do Arquivo

```
extends CharacterBody3D
class_name InimigoBase

enum Categoria { NORMAL, MINI_BOSS, BOSS }

@export — identidade (nome, tipo, dica, status)
@export — combate (hp, velocidade, dano, distancia, recarga)
@export — visão (raio_construcao, raio_aliados)
@export_node_path — modelo_3d, animation_player

variáveis de estado (vida_atual, alvo_atual, pode_atacar, etc.)
@onready — nav_agent, SensorAtaque

_ready()
_physics_process(delta)
procurar_novo_alvo() → Node3D
receber_dano(qtd, origem)
_verificar_travamento()
_on_sensor_ataque_body_entered(body)
morrer()
```

---

## Propriedades Exportadas

```gdscript
# Identidade
@export var tipo_inimigo: Categoria
@export var nome_inimigo: String
@export var dica_tutorial: String
@export var status_velocidade: String
@export var status_vida: String

# Combate
@export var vida_maxima: int
@export var velocidade: float
@export var forca_dano: int
@export var distancia_ataque: float
@export var tempo_recarga_ataque: float

# Visão
@export var raio_visao_construcao: float
@export var raio_visao_aliados: float
```

---

## `procurar_novo_alvo()` — Lógica de Busca

Hierarquia de prioridade:
1. Construções no grupo `"construcoes"` dentro do `raio_visao_construcao`
2. Fallback: `get_first_node_in_group("Castelo")`
3. Fallback adicional: `get_first_node_in_group("Base")`

```gdscript
var base_principal = get_tree().get_first_node_in_group("Castelo")
if not base_principal:
    base_principal = get_tree().get_first_node_in_group("Base")
return base_principal
```

> 📌 O fallback para `"Base"` foi adicionado especificamente para o [[Mapas/FendaDosPiratas]], onde a base é `BarcoBase.tscn` (grupo `"Base"`, não `"Castelo"`).

---

## Verificação Periódica de Alvo

Timer interno re-verifica o alvo quando:
- Alvo destruído (`not is_instance_valid(alvo_atual)`)
- Alvo é a base principal (procura construção mais próxima)

```gdscript
elif alvo_atual.is_in_group("Castelo") or alvo_atual.is_in_group("Base"):
    var candidato = procurar_candidato_proximo()
    if is_instance_valid(candidato) and \
       not candidato.is_in_group("Castelo") and \
       not candidato.is_in_group("Base"):
        alvo_atual = candidato
```

---

## `_physics_process(delta)` — Fluxo

```
1. Aplica gravidade se not is_on_floor()
2. nav_agent.target_position = alvo_atual.global_position
3. if not nav_agent.is_navigation_finished():
       dir = nav_agent.get_next_path_position() - global_position
       velocity = dir.normalized() * velocidade * multiplicador
   else:
       velocity.x = 0; velocity.z = 0
4. move_and_slide()
```

> ⚠️ Velocity setada DEPOIS deste método (em subclasses) só é aplicada no próximo frame.  
> Solução: chamar `move_and_slide()` de novo após setar velocity. Ver [[Sistemas/Navegação e Movimento]].

---

## Grupos

```gdscript
func _ready():
    add_to_group("inimigos")
```

Todos os inimigos estão em `"inimigos"`. O [[Sistemas/Ondas e Spawner]] usa isso para detectar limpeza de onda:
```gdscript
while get_tree().get_nodes_in_group("inimigos").size() > 0:
    await get_tree().create_timer(1.0).timeout
```

---

## `limite_queda_y` e `posicao_de_spawn`

```gdscript
var posicao_de_spawn: Vector3 = Vector3.ZERO  # ⚠️ DEVE ser sobrescrito
var limite_queda_y: float = -20.0
```

Se o inimigo cair abaixo de `limite_queda_y`, é teleportado para `posicao_de_spawn`.  
Como o valor padrão é `Vector3.ZERO`, inimigos que não inicializam `posicao_de_spawn` vão parar na origem do mapa.

**Solução aplicada no HolandesVoador:**
```gdscript
posicao_de_spawn = global_position  # no _ready() após await
```

---

## Relações

- [[Sistemas/InimigoBase]] — nota conceitual desta classe (arquitetura, propriedades, comportamento)
- [[Inimigos/HolandesVoador]] — herda e estende com `_physics_process` e `receber_dano` próprios
- [[Código/holandes_voador.gd]] — subclasse concreta; demonstra o padrão do segundo `move_and_slide()`
- [[Inimigos/Categorias de Inimigos]] — enum `Categoria` declarado aqui; define NORMAL/MINI_BOSS/BOSS
- [[Sistemas/Navegação e Movimento]] — documenta os bugs de `move_and_slide()` e `is_navigation_finished()`
- [[Sistemas/GameManager]] — `multiplicador_velocidade_inimigo` consumido em `_physics_process()`
- [[Sistemas/TelaAvisoInimigo]] — campos `nome_inimigo`, `dica_tutorial`, `tipo_inimigo` alimentam esta UI
- [[Sistemas/Ondas e Spawner]] — instancia e posiciona inimigos; define timing do spawn
- [[Código/spawner_inimigos.gd]] — código que seta `global_position` após `add_child`
- [[Mapas/FendaDosPiratas]] — motivou o fallback `"Base"` em `procurar_novo_alvo()`
- [[Referência Rápida — Bugs e Soluções]] — `posicao_de_spawn = Vector3.ZERO` e outros bugs desta classe

---

## Tags

`#codigo` `#classe-base` `#gdscript` `#navegacao` `#combate`
