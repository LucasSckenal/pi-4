# 🧭 Navegação & Movimento

#sistema #navegacao #pathfinding #bug-fix

> Documentação do sistema de navegação com NavigationAgent3D — comportamentos esperados, bugs conhecidos e soluções aplicadas.

---

## Resumo

A navegação usa `NavigationAgent3D` do Godot 4. O agente calcula caminhos no navmesh e retorna a **próxima posição** que o inimigo deve se mover a cada frame. O maior desafio é o **comportamento no frame inicial** e casos onde o agente não produz movimento mesmo com alvo válido.

---

## Como Funciona

```gdscript
# A cada frame em _physics_process:
nav_agent.target_position = alvo_atual.global_position
var next_pos = nav_agent.get_next_path_position()
var direction = (next_pos - global_position).normalized()
velocity.x = direction.x * velocidade
velocity.z = direction.z * velocidade
move_and_slide()
```

---

## ⚠️ Bug: `is_navigation_finished()` trava em `true`

### Problema
`is_navigation_finished()` retorna `true`:
- No **primeiro frame** antes de qualquer path ser calculado
- Quando o agente ainda não recebeu `target_position`
- Quando o inimigo está **exatamente** na posição do alvo

Resultado: inimigo não se move logo após spawn.

### Causa Raiz no HolandesVoador
O `_ready()` usa `await get_tree().process_frame` antes de configurar o alvo.  
Isso significa que `_physics_process` **já executa uma vez** antes de `_ready` terminar o setup → sem alvo → nav_agent nunca recebe `target_position` → `is_navigation_finished()` = `true` permanentemente.

### Solução Aplicada ([[Inimigos/HolandesVoador]])
```gdscript
func _ready() -> void:
    super._ready()
    await get_tree().process_frame  # aguarda spawner definir global_position
    
    # Setup APÓS o frame
    alvo_atual = procurar_novo_alvo()
    if alvo_atual and nav_agent:
        nav_agent.target_position = alvo_atual.global_position  # pré-aquece
```

---

## ⚠️ Bug: `move_and_slide()` duplo necessário

### Problema
`super._physics_process(delta)` já chama `move_and_slide()` ao final.  
Qualquer velocity setada **depois** do super só é aplicada no **próximo frame** — onde pode ser sobrescrita novamente antes de gerar movimento real.

### Padrão Anti-Travamento (Fallback Inline)
```gdscript
func _physics_process(delta: float) -> void:
    super._physics_process(delta)  # ← já chama move_and_slide() aqui
    
    # Verifica se o boss está parado mas deveria estar se movendo
    var dist_xz = Vector2(global_position.x - alvo_pos.x,
                          global_position.z - alvo_pos.z).length()
    var vel_horiz = Vector2(velocity.x, velocity.z).length_squared()
    
    if dist_xz > distancia_ataque and vel_horiz < 0.001:
        # Aplica direção direta
        velocity.x = dir.x * vel
        velocity.z = dir.z * vel
        move_and_slide()  # ← segundo call no MESMO frame → garante movimento imediato
```

---

## ⚠️ Bug: `posicao_de_spawn = Vector3.ZERO`

### Problema
`InimigoBase._ready()` nunca inicializa `posicao_de_spawn`. Se o inimigo cai abaixo do `limite_queda_y`, ele é teleportado para `Vector3.ZERO` (origem do mapa).

### Solução
```gdscript
# holandes_voador._ready(), após await:
posicao_de_spawn = global_position
```

---

## ⚠️ Bug: Spawner fora do NavMesh

### Problema
Se o spawner está ligeiramente fora do navmesh, `NavigationServer3D` não consegue calcular caminho a partir daquela posição.

### Solução
```gdscript
var nav_map := get_world_3d().navigation_map
var pos_valida := NavigationServer3D.map_get_closest_point(nav_map, global_position)
if pos_valida.distance_to(global_position) > 0.3:
    global_position = pos_valida  # encaixa no navmesh mais próximo
```

---

## Regras de Ouro

1. **Nunca setar velocity depois de `super._physics_process()`** sem chamar `move_and_slide()` de novo
2. **Sempre pré-aquecer `nav_agent.target_position`** no `_ready()` após o frame de setup
3. **Sempre inicializar `posicao_de_spawn`** ao final do `_ready()` do inimigo
4. **Verificar posição no navmesh** se o spawner pode estar fora do navmesh

---

## Relações

- [[Sistemas/InimigoBase]] — implementação base da navegação; detém a lógica de `_physics_process`
- [[Código/inimigo_base.gd]] — código onde `move_and_slide()` é chamado (e onde o bug acontece)
- [[Inimigos/HolandesVoador]] — caso mais complexo: bugs de spawn + teleporte + navmesh
- [[Código/holandes_voador.gd]] — implementa o fallback duplo `move_and_slide()` e o pré-aquecimento de nav
- [[Sistemas/Ondas e Spawner]] — define `global_position` APÓS `add_child`, raiz do bug de timing
- [[Código/spawner_inimigos.gd]] — linha exata onde `inimigo.global_position = global_position` acontece
- [[Sistemas/TelaAvisoInimigo]] — pausa o jogo via `get_tree().paused` → suspende `_physics_process`
- [[Mapas/FendaDosPiratas]] — spawners deste mapa podem estar fora do navmesh
- [[Referência Rápida — Bugs e Soluções]] — lista consolidada de todos os bugs de navegação

---

## Tags

`#sistema` `#navegacao` `#bug-fix` `#pathfinding` `#navigationagent3d`
