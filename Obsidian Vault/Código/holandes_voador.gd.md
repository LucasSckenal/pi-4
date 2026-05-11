# 💻 holandes_voador.gd

#codigo #boss #gdscript

> Script do boss [[Inimigos/HolandesVoador]]. Herda de `InimigoBase` e adiciona a habilidade Salto Fantasma.

**Caminho:** `Enemys/holandes_voador.gd`

---

## Estrutura do Arquivo

```
extends InimigoBase
class_name HolandesVoador

SINAIS (3)
CONFIGURAÇÕES @export (4 vars)
ESTADO interno (4 vars)
_ready()
_physics_process(delta)
receber_dano(qtd, origem)
_salto_fantasma()
_selecionar_novo_caminho() → Vector3
```

---

## Sinais

```gdscript
signal start_teleport_effect(pos: Vector3)
signal teleport_disappear
signal teleport_reappear(pos: Vector3)
```

---

## Variáveis de Estado Importantes

```gdscript
var initial_path: Vector3    # posição do spawner original
var current_path: Vector3    # posição do spawner atual
var has_teleported: bool     # trava — só teleporta 1 vez por vida
var is_teleporting: bool     # bloqueia movement durante o efeito
```

---

## `_ready()`

### Por que `await get_tree().process_frame`?
O `spawner_inimigos.gd` faz:
```gdscript
get_tree().current_scene.add_child(inimigo)
inimigo.global_position = global_position  # DEPOIS de add_child
```
Se não houver await, `global_position` ainda é `Vector3.ZERO` quando o boss lê sua posição em `_ready()`.

### Pré-aquecimento da navegação
```gdscript
alvo_atual = procurar_novo_alvo()
if alvo_atual and nav_agent:
    nav_agent.target_position = alvo_atual.global_position
```
Sem isso, `is_navigation_finished()` retorna `true` no primeiro frame e o boss nunca anda. Ver [[Sistemas/Navegação e Movimento]].

---

## `_physics_process(delta)`

### Guard para teleporte
```gdscript
if is_teleporting:
    # apenas gravidade, sem horizontal
    velocity.x = 0.0
    velocity.z = 0.0
    move_and_slide()
    return
```

### Fallback anti-travamento (após `super._physics_process`)
```gdscript
# Condição: boss longe do alvo MAS sem velocidade horizontal
if dist_xz > distancia_ataque and vel_horiz < 0.001:
    # Aplica direção direto
    velocity.x = dir.x * vel
    velocity.z = dir.z * vel
    move_and_slide()  # segundo call no mesmo frame!
```

> ⚠️ O segundo `move_and_slide()` é necessário porque `super._physics_process` já chamou o primeiro. Velocity setada depois só seria aplicada no próximo frame. Ver [[Sistemas/Navegação e Movimento#Bug move_and_slide() duplo necessário]].

---

## `receber_dano(qtd, origem)`

```gdscript
func receber_dano(qtd: int, origem: String = "torre") -> void:
    super.receber_dano(qtd, origem)
    
    if has_teleported or is_teleporting or esta_morto:
        return
    
    var porcentagem = float(vida_atual) / float(vida_maxima)
    if porcentagem <= hp_gatilho_teleporte:
        _salto_fantasma()
```

Trava tripla: não ativa se já teleportou, está teleportando ou morreu neste hit.

---

## `_selecionar_novo_caminho() → Vector3`

```gdscript
func _selecionar_novo_caminho() -> Vector3:
    var spawners = get_tree().get_nodes_in_group("Spawner")
    var candidatos: Array[Vector3] = []
    
    for spawner in spawners:
        var pos = spawner.global_position
        if pos.distance_to(current_path) < 1.0: continue  # exclui atual
        if pos.distance_to(initial_path) < 1.0: continue  # exclui spawn
        candidatos.append(pos)
    
    if candidatos.is_empty():
        return Vector3.ZERO  # nenhum candidato → aborta teleporte
    
    return candidatos[randi() % candidatos.size()]
```

---

## Histórico de Bugs Corrigidos

### Bug 1: Type inference error (linha 105)
```
Erro: Cannot infer the type of "vel_aplic" variable
```
**Causa:** `GameManager.multiplicador_velocidade_inimigo` sem tipo declarado  
**Fix:** `var vel: float = velocidade * max(0.1, GameManager.multiplicador_velocidade_inimigo as float)`

### Bug 2: Boss parado ao spawnar
**Causa:** `_verificar_travamento` setava velocity DEPOIS do `move_and_slide()` do super → velocity só aplicada no próximo frame → boss nunca sai do lugar  
**Fix:** Fallback inline com segundo `move_and_slide()` no mesmo frame

### Bug 3: Boss teleporta para Vector3.ZERO
**Causa:** `posicao_de_spawn` nunca inicializado → queda abaixo do `limite_queda_y` teletransporta para origem  
**Fix:** `posicao_de_spawn = global_position` no `_ready()` após await

---

## Relações

- [[Inimigos/HolandesVoador]] — nota conceitual completa do boss (stats, habilidade, fluxo)
- [[Sistemas/InimigoBase]] — classe pai com toda lógica base
- [[Código/inimigo_base.gd]] — código da classe base; `_physics_process` que chama `move_and_slide()`
- [[Sistemas/Navegação e Movimento]] — documenta os bugs de pathfinding resolvidos neste arquivo
- [[Sistemas/GameManager]] — `multiplicador_velocidade_inimigo` lido na linha ~105 (requer `as float`)
- [[Sistemas/Ondas e Spawner]] — define a posição do boss com `global_position` pós `add_child`
- [[Código/spawner_inimigos.gd]] — código que justifica o `await get_tree().process_frame` no `_ready()`
- [[Inimigos/Categorias de Inimigos]] — este boss é `Categoria.BOSS` (tipo = 2)
- [[Mapas/FendaDosPiratas]] — único mapa onde este script é usado; spawners servem de destino de teleporte
- [[Referência Rápida — Bugs e Soluções]] — 3 bugs documentados: tipo, travamento, origin teleport

---

## Tags

`#codigo` `#boss` `#gdscript` `#teleporte` `#bug-fix`
