# ⚠️ TelaAvisoInimigo

#sistema #ui #pausa #tutorial

> Tela exibida na primeira vez que um tipo de inimigo aparece. Pausa o jogo e exibe dica de como lidar com ele.

---

## Resumo

Quando um inimigo de tipo **nunca antes visto** aparece na tela, o jogo é pausado automaticamente e exibe uma tela de aviso com a dica de tutorial. O jogador deve clicar para continuar.

---

## Comportamento

```
Inimigo spawna pela primeira vez
        │
        ▼
InimigoBase detecta "tipo inédito"
        │
        ▼
TelaAvisoInimigo.mostrar(nome, dica)
        │
        ▼
get_tree().paused = true   ← PAUSA O JOGO
        │
        ▼
Jogador clica em "OK" / "Continuar"
        │
        ▼
get_tree().paused = false  ← RETOMA
```

---

## Dados Usados da [[Sistemas/InimigoBase]]

| Campo | Origem | Uso |
|-------|--------|-----|
| `nome_inimigo` | `@export` | Título da tela de aviso |
| `dica_tutorial` | `@export` | Texto explicativo |
| `tipo_inimigo` | `@export` | Identifica se é tipo inédito |

---

## ⚠️ Impacto na Navegação

A pausa via `get_tree().paused = true` **suspende `_physics_process`** em todos os nós com `process_mode` padrão.

Isso significa que:
- O [[Inimigos/HolandesVoador]] pode ter seu `_ready()` interrompido durante o `await get_tree().process_frame`
- O `NavigationAgent3D` não processa durante a pausa
- Quando a pausa termina, o agente pode não ter path calculado → `is_navigation_finished() = true`

> 📌 Isso é uma das causas possíveis do boss ficar parado no primeiro frame. Ver [[Sistemas/Navegação e Movimento]].

---

## Exemplo de Dica (HolandesVoador)

```
"O Holandês Voador! A 50% de vida ele some e reaparece num outro 
ponto do mapa. Prepare suas defesas por todos os lados!"
```

---

## Relações

- [[Sistemas/InimigoBase]] — fornece `nome_inimigo`, `dica_tutorial` e `tipo_inimigo`
- [[Código/inimigo_base.gd]] — código que detecta primeiro encontro e dispara a tela
- [[Inimigos/HolandesVoador]] — primeiro boss a acionar essa tela; tem dica específica de teleporte
- [[Inimigos/Categorias de Inimigos]] — a categoria (`tipo_inimigo`) determina se o aviso é exibido; bosses têm prioridade
- [[Sistemas/Navegação e Movimento]] — a pausa via `get_tree().paused` pode causar `is_navigation_finished() = true`
- [[Mapas/FendaDosPiratas]] — mapa onde o HolandesVoador aparece pela primeira vez, ativando esta tela

---

## Tags

`#sistema` `#ui` `#tutorial` `#pausa`
