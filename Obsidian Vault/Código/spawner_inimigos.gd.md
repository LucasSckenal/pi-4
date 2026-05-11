# 💻 spawner_inimigos.gd

#codigo #spawner #ondas #gdscript

> Script de spawner. Gerencia fila de inimigos, timing de spawn, modo infinito e conclusão de onda.

**Caminho:** `Cenas Locais/spawner_inimigos.gd`

---

## Estrutura do Arquivo

```
extends Node3D

signal info_proxima_onda(direcao, inimigos, posicao)

@export — ondas: Array[WaveData]
@export — label_wave: Label

variáveis de estado
  onda_atual, fila_inimigos, fila_hp_mult
  inimigos_restantes, spawning

pool_normais, cena_boss  (modo infinito)

@onready — timer, base

_ready()
_iniciar_noite(n)
_on_timer_timeout()
_spawnar_proximo()
_esperar_limpeza()
_finalizar_onda()
emitir_info()
_calcular_direcao() → String
restaurar_onda_do_save()
_construir_pool_procedural()
_calcular_hp_multiplicador(onda) → float
_gerar_onda_procedural(onda) → WaveData
```

---

## Inicialização

```gdscript
func _ready():
    add_to_group("Spawner")          # boss usa para teleporte
    GameManager.noite_iniciada.connect(_iniciar_noite)
    timer.timeout.connect(_on_timer_timeout)
    _construir_pool_procedural()     # detecta boss vs normais
    emitir_info()                    # UI: próxima onda
```

---

## Ciclo de Vida de uma Onda

### 1. `_iniciar_noite(n)`
```gdscript
# Monta fila_inimigos[] e fila_hp_mult[]
# Cada inimigo da onda gera um entry na fila
# mult_horda (pre-defined) ou 1.0 (procedural)
for config in onda_data.inimigos:
    var qtd = int(ceil(config.quantidade * mult_horda))
    for i in range(qtd):
        fila_inimigos.append(config.cena)
        fila_hp_mult.append(hp_mult_base)
```

### 2. `_spawnar_proximo()`
```gdscript
var inimigo = cena.instantiate()
# Aplica HP scaling ANTES de add_child para que _ready() veja o valor escalado
if hp_mult > 1.0 and "vida_maxima" in inimigo:
    inimigo.vida_maxima = int(inimigo.vida_maxima * hp_mult)
get_tree().current_scene.add_child(inimigo)
inimigo.global_position = global_position  # ← posição APÓS add_child
```

> ⚠️ O inimigo é posicionado DEPOIS de `add_child`. Por isso o [[Código/holandes_voador.gd]] usa `await get_tree().process_frame` no `_ready()`.

### 3. `_esperar_limpeza()`
```gdscript
while get_tree().get_nodes_in_group("inimigos").size() > 0:
    await get_tree().create_timer(1.0).timeout
_finalizar_onda()
```

### 4. `_finalizar_onda()`
```gdscript
onda_atual += 1
GameManager.registrar_spawner_concluido()
emitir_info()
```

---

## Pool Procedural

### `_construir_pool_procedural()`
Percorre todas as `ondas` pre-definidas e detecta boss:
```gdscript
var instancia = config.cena.instantiate()
var eh_boss = (instancia.tipo_inimigo == InimigoBase.Categoria.BOSS
            or instancia.tipo_inimigo == InimigoBase.Categoria.MINI_BOSS)
instancia.free()  # descarta imediatamente após inspeção
```

### `_gerar_onda_procedural(onda_global)`
- Seed determinística por onda e por spawner: `hash(str(onda) + "_" + name)`
- `qtd_por_spawner = clamp(3 + floor(onda/4), 3, 8)`
- Boss só no `spawners[0]` a cada 5 ondas

### `_calcular_hp_multiplicador(onda)`
```gdscript
return 1.0 + max(0, onda_global - 5) * 0.15
# Onda 6: 1.15x | Onda 10: 1.75x | Onda 20: 3.25x
```

---

## UI: `emitir_info()`

Emite `info_proxima_onda` com:
- `direcao`: "Norte" / "Sul" / "Leste" / "Oeste" (baseado em ângulo para a base)
- `inimigos`: array de `{icone, cor, qtd}`
- `posicao`: `global_position` do spawner

---

## `restaurar_onda_do_save()`

```gdscript
func restaurar_onda_do_save():
    onda_atual = GameManager.onda_atual - 1
    emitir_info()
```

Usado ao carregar um save para sincronizar o estado do spawner com o GameManager.

---

## Relações

- [[Sistemas/Ondas e Spawner]] — nota conceitual completa deste sistema
- [[Sistemas/GameManager]] — escuta `noite_iniciada`; chama `registrar_spawner_concluido()`
- [[Sistemas/InimigoBase]] — classe base de todos os inimigos instanciados aqui
- [[Código/inimigo_base.gd]] — código que recebe `global_position` pós `add_child` (causa do `await`)
- [[Inimigos/HolandesVoador]] — boss instanciado neste spawner; usa grupo "Spawner" para teleporte
- [[Código/holandes_voador.gd]] — usa `await process_frame` porque este script seta posição após `add_child`
- [[Inimigos/Categorias de Inimigos]] — `_construir_pool_procedural()` instancia temp. para checar `tipo_inimigo`
- [[Sistemas/TelaAvisoInimigo]] — spawn de novo tipo de inimigo aciona esta tela
- [[Sistemas/Navegação e Movimento]] — posição seta após `add_child` cria janela de 1 frame sem nav válido
- [[Mapas/FendaDosPiratas]] — contém múltiplas instâncias deste spawner; spawner[0] spawna o boss; tem [[Sistemas/Shaders e Efeitos Visuais|efeito visual de bolhas]] ativo no mapa
- [[Referência Rápida — Bugs e Soluções]] — timing de spawn é a causa raiz do bug "boss parado"

---

## Tags

`#codigo` `#spawner` `#ondas` `#procedural` `#gdscript`
