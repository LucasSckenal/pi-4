# 🏴‍☠️ Fenda dos Piratas

#mapa #piratas #boss #bolhas

> Mapa temático de piratas. Apresenta o [[Inimigos/HolandesVoador]] como boss e tem efeito visual de bolhas subindo pela tela.

---

## Resumo

A Fenda dos Piratas é o mapa com temática aquática/pirata. Diferente de outros mapas, a base defensora aqui é o **BarcoBase** (não um Castelo), o que exige tratamento especial no sistema de busca de alvos dos inimigos.

---

## Características Únicas

### Base: BarcoBase (não Castelo)
```gdscript
# Builds.gd — BarcoBase
add_to_group("Base")   # ← grupo "Base", NÃO "Castelo"
```

Isso significa que `InimigoBase.procurar_novo_alvo()` precisa do fallback para o grupo `"Base"`:

```gdscript
var base_principal = get_tree().get_first_node_in_group("Castelo")
if not base_principal:
    base_principal = get_tree().get_first_node_in_group("Base")  # ← essencial aqui
```

Ver [[Sistemas/InimigoBase]] para detalhes.

### Efeito Visual: Bolhas
```gdscript
# fenda_dos_piratas.gd
const BolhasFundo = preload("res://Cenas Locais/bolhas_fundo.tscn")

func _ready():
    add_child(BolhasFundo.instantiate())
```

Bolhas animadas sobem pela tela continuamente, criando atmosfera subaquática. Ver [[Sistemas/Shaders e Efeitos Visuais]] para detalhes técnicos.

---

## Boss

| Boss | Condição de Aparição |
|------|---------------------|
| [[Inimigos/HolandesVoador]] | Ondas específicas / onda de boss a cada 5 no modo infinito |

O boss usa os spawners do mapa como destinos de teleporte. Com múltiplos spawners, o Salto Fantasma pode levá-lo a qualquer ponto do mapa.

---

## Layout de Spawners

O mapa tem múltiplos spawners, cada um adicionado ao grupo `"Spawner"` automaticamente. O [[Inimigos/HolandesVoador]] filtra:
- Spawner de origem (`initial_path`)
- Spawner atual (`current_path`)

Para teleportar para um spawner diferente.

> 📌 Com apenas 2 spawners no mapa, pode acontecer de não haver candidatos válidos para teleporte (ambos excluídos). O `_selecionar_novo_caminho()` retorna `Vector3.ZERO` nesse caso e o teleporte é abortado.

---

## Arquivos do Mapa

| Arquivo | Função |
|---------|--------|
| `Maps/fenda_dos_piratas.tscn` | Cena principal do mapa |
| `Maps/fenda_dos_piratas.gd` | Script com load das bolhas |
| `Cenas Locais/bolhas_fundo.tscn` | Efeito de bolhas |
| `Shaders/Bolhas.gdshader` | Shader das bolhas |

---

## Checklist de Setup do Mapa

- [x] BarcoBase no grupo `"Base"`
- [x] Spawners com script `spawner_inimigos.gd` e ondas configuradas
- [x] `HolandesVoador` incluído em alguma onda
- [x] Efeito de bolhas adicionado via `_ready()`
- [x] Navmesh cobre todos os caminhos dos spawners até a base

---

## Relações

- [[Inimigos/HolandesVoador]] — boss principal; usa spawners do mapa para teleportar
- [[Código/holandes_voador.gd]] — script do boss; `_selecionar_novo_caminho()` lista spawners deste mapa
- [[Inimigos/Categorias de Inimigos]] — BOSS e NORMAL convivem nas ondas deste mapa
- [[Sistemas/Ondas e Spawner]] — múltiplos spawners gerenciam as hordas
- [[Código/spawner_inimigos.gd]] — script dos spawners posicionados no mapa
- [[Sistemas/InimigoBase]] — usa grupo `"Base"` em vez de `"Castelo"` (BarcoBase)
- [[Código/inimigo_base.gd]] — `procurar_novo_alvo()` com fallback `"Base"` adicionado para este mapa
- [[Sistemas/Shaders e Efeitos Visuais]] — efeito de bolhas instanciado no `_ready()` deste mapa
- [[Código/Bolhas.gdshader]] — shader GLSL aplicado via `bolhas_fundo.tscn`
- [[Sistemas/GameManager]] — gerencia ondas e multiplicadores neste mapa
- [[Sistemas/TelaAvisoInimigo]] — ativada quando HolandesVoador aparece pela primeira vez
- [[Sistemas/Navegação e Movimento]] — navmesh deve cobrir caminhos de todos os spawners até o BarcoBase
- [[Referência Rápida — Bugs e Soluções]] — inimigos não encontrando base foi bug específico deste mapa

---

## Tags

`#mapa` `#piratas` `#boss` `#bolhas` `#barco-base` `#fenda-dos-piratas`
