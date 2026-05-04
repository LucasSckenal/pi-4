# 👾 Categorias de Inimigos

#inimigo #enum #categorias #boss

> Sistema de categorização de inimigos via enum. Define comportamentos, spawn e scaling de dificuldade.

---

## Enum `InimigoBase.Categoria`

```gdscript
enum Categoria {
    NORMAL   = 0,
    MINI_BOSS = 1,
    BOSS     = 2
}
```

---

## Uso por Sistema

### [[Sistemas/Ondas e Spawner]] — Pool Procedural

O spawner usa a categoria para separar inimigos em dois pools:

```gdscript
var eh_boss = (instancia.tipo_inimigo == InimigoBase.Categoria.BOSS
            or instancia.tipo_inimigo == InimigoBase.Categoria.MINI_BOSS)

if eh_boss:
    cena_boss = config.cena      # apenas 1 boss (o primeiro encontrado)
else:
    pool_normais.append(config.cena)
```

**Regras de spawn em modo infinito:**
- Inimigos `NORMAL` e `MINI_BOSS` → distribuídos entre todos os spawners
- `BOSS` → apenas o `spawners[0]` spawna o boss (evita 3 bosses simultâneos)
- Ondas de boss: a cada 5 ondas (`onda_global % 5 == 0`)

### [[Sistemas/TelaAvisoInimigo]]
A tela de aviso é exibida com base na primeira aparição do tipo (`tipo_inimigo`). Bosses geralmente têm dicas mais elaboradas.

---

## Inimigos por Categoria

### BOSS (tipo = 2)
| Inimigo | HP | Habilidade Especial |
|---------|----|--------------------|
| [[Inimigos/HolandesVoador]] | 1800 | Salto Fantasma (teleporte) |

### MINI_BOSS (tipo = 1)
> *Documente aqui quando novos mini-bosses forem adicionados.*

### NORMAL (tipo = 0)
> *Documente aqui os inimigos normais quando disponíveis.*

---

## Scaling de Dificuldade

| Categoria | HP Scaling (Modo Infinito) | Quantidade |
|-----------|--------------------------|-----------|
| NORMAL | `1.0 + max(0, onda-5) * 0.15` | `clamp(3 + floor(onda/4), 3, 8)` |
| MINI_BOSS | Mesmo multiplicador | Incluído no pool normal |
| BOSS | Mesmo multiplicador | 1 por onda de boss, só spawner[0] |

---

## Como Classificar um Novo Inimigo

1. No `.tscn`, setar `tipo_inimigo = 0/1/2`
2. Se for BOSS ou MINI_BOSS: o spawner o detectará automaticamente na construção do pool
3. Se for BOSS: garantir que tem habilidade especial e `vida_maxima` alta

---

## Relações

- [[Sistemas/InimigoBase]] — define o enum `Categoria`; toda lógica de tipo parte daqui
- [[Código/inimigo_base.gd]] — código onde o enum está declarado
- [[Sistemas/Ondas e Spawner]] — usa `Categoria` para separar pool procedural em boss/normais
- [[Código/spawner_inimigos.gd]] — `_construir_pool_procedural()` instancia temporariamente para checar `tipo_inimigo`
- [[Inimigos/HolandesVoador]] — único BOSS implementado até agora
- [[Código/holandes_voador.gd]] — `tipo_inimigo = 2` setado na `.tscn`
- [[Sistemas/GameManager]] — HP scaling por onda aplica-se a todas as categorias
- [[Sistemas/TelaAvisoInimigo]] — exibe aviso na primeira aparição de cada `tipo_inimigo`
- [[Mapas/FendaDosPiratas]] — mapa onde BOSS e NORMAL interagem no mesmo ciclo de ondas

---

## Tags

`#inimigo` `#enum` `#categorias` `#boss` `#mini-boss` `#normal`
