# 🐛 Referência Rápida — Bugs & Soluções

#bug-fix #referencia #godot4

> Todos os bugs documentados neste projeto com causa raiz e solução aplicada. Útil como checklist quando algo para de funcionar.

---

## 🔴 Inimigo parado ao spawnar

**Sintoma:** Boss ou inimigo aparece mas não se move  
**Arquivo:** [[Código/holandes_voador.gd]], [[Código/inimigo_base.gd]]

| Causa | Solução |
|-------|---------|
| `is_navigation_finished()` = `true` no 1º frame | Pré-aquecer `nav_agent.target_position` no `_ready()` após `await process_frame` |
| Velocity setada DEPOIS de `move_and_slide()` | Chamar `move_and_slide()` uma 2ª vez após setar velocity manual |
| Spawner fora do navmesh | `NavigationServer3D.map_get_closest_point()` para encaixar no navmesh |
| `await process_frame` causa execução de `_physics_process` antes do setup | Pré-aquecer navegação DENTRO do `_ready()` após o await |

Ver: [[Sistemas/Navegação e Movimento]]

---

## 🔴 Inimigo teleporta para a origem (0,0,0)

**Sintoma:** Inimigo cai e reaparece no centro do mapa  
**Arquivo:** [[Código/holandes_voador.gd]], [[Código/inimigo_base.gd]]

| Causa | Solução |
|-------|---------|
| `posicao_de_spawn = Vector3.ZERO` (padrão) | Setar `posicao_de_spawn = global_position` no `_ready()` após `await process_frame` |

---

## 🔴 Erro de tipo ao ler GameManager

**Sintoma:** `Cannot infer the type of "x" variable because the value doesn't have a set type`  
**Arquivo:** [[Código/holandes_voador.gd]] linha ~105

| Causa | Solução |
|-------|---------|
| `GameManager.multiplicador_velocidade_inimigo` não tem tipo declarado | Usar `as float`: `var vel: float = x * (y as float)` |

---

## 🔴 Inimigos não encontram a base (fenda dos piratas)

**Sintoma:** Inimigos ficam parados ou não atacam nada  
**Arquivo:** [[Código/inimigo_base.gd]]

| Causa | Solução |
|-------|---------|
| `procurar_novo_alvo()` só busca grupo `"Castelo"`, mas fenda usa `"Base"` | Adicionar fallback: `if not base: base = get_first_node_in_group("Base")` |

Ver: [[Mapas/FendaDosPiratas]], [[Sistemas/InimigoBase]]

---

## 🟡 Boss executa teleporte múltiplas vezes

**Sintoma:** Salto Fantasma ativa mais de uma vez  
**Arquivo:** [[Código/holandes_voador.gd]]

| Causa | Solução |
|-------|---------|
| Múltiplos danos simultâneos passam pela verificação antes do flag ser setado | Trava dupla: verificar `has_teleported` E `is_teleporting` antes de chamar `_salto_fantasma()` |

---

## 🟡 ColorRect de shader bloqueia cliques

**Sintoma:** Cliques na UI não funcionam após adicionar efeito visual  
**Arquivo:** `Cenas Locais/bolhas_fundo.tscn`

| Causa | Solução |
|-------|---------|
| `ColorRect` intercepta eventos de mouse por padrão | Setar `mouse_filter = 2` (IGNORE) no ColorRect |

Ver: [[Sistemas/Shaders e Efeitos Visuais]]

---

## 🟡 Boss não tem candidatos para teleporte

**Sintoma:** Salto Fantasma é abortado silenciosamente  
**Arquivo:** [[Código/holandes_voador.gd]]

| Causa | Solução |
|-------|---------|
| Mapa tem apenas 2 spawners; ambos são excluídos (atual + inicial) | `_selecionar_novo_caminho()` retorna `Vector3.ZERO` → teleporte abortado gracefully. Adicionar mais spawners ao mapa. |

---

## Checklist Ao Criar Novo Inimigo

- [ ] Herda `InimigoBase` e seta `tipo_inimigo`
- [ ] Define `nome_inimigo` e `dica_tutorial`
- [ ] Se boss: tem `class_name` e sobrescreve `receber_dano()`
- [ ] Inicializa `posicao_de_spawn = global_position` no `_ready()` após spawn
- [ ] Se usa `_physics_process`: chamar `super._physics_process(delta)` PRIMEIRO
- [ ] Testa no navmesh do mapa alvo (não só no mapa de testes)
- [ ] Adiciona ao `WaveData` da onda correta

---

## Relações

← Voltar ao [[Index]]

### Sistemas afetados pelos bugs
- [[Sistemas/Navegação e Movimento]] — bugs de pathfinding (is_navigation_finished, move_and_slide duplo)
- [[Sistemas/InimigoBase]] — classe base; `posicao_de_spawn` e `procurar_novo_alvo()` problemáticos
- [[Sistemas/GameManager]] — fonte do `multiplicador_velocidade_inimigo` sem tipo declarado
- [[Sistemas/Ondas e Spawner]] — timing de `global_position` após `add_child` causa bug de spawn
- [[Sistemas/TelaAvisoInimigo]] — pausa via `get_tree().paused` pode congelar pathfinding
- [[Sistemas/Shaders e Efeitos Visuais]] — `mouse_filter = 2` esquecido bloqueia cliques do player

### Inimigos com bugs corrigidos
- [[Inimigos/HolandesVoador]] — boss com maior histórico de bugs (3 corrigidos)
- [[Inimigos/Categorias de Inimigos]] — `tipo_inimigo` não tipado causa problemas de inferência

### Código com bugs corrigidos
- [[Código/holandes_voador.gd]] — 3 bugs documentados com causa e fix
- [[Código/inimigo_base.gd]] — `posicao_de_spawn`, `procurar_novo_alvo()`, `move_and_slide()`
- [[Código/spawner_inimigos.gd]] — timing de posição é a raiz do bug "boss parado"

### Mapas que motivaram correções
- [[Mapas/FendaDosPiratas]] — motivou fallback grupo `"Base"` e fix de spawner fora do navmesh

---

## Tags

`#bug-fix` `#referencia` `#checklist` `#godot4`
