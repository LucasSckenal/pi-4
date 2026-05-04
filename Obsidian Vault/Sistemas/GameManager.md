# 🎮 GameManager

#sistema #global #singleton

> Singleton global que controla o estado central da partida: ondas, multiplicadores, modo infinito e sincronização entre spawners.

---

## Resumo

O `GameManager` é o **cérebro da partida**. Todos os [[Sistemas/Ondas e Spawner|Spawners]] escutam o sinal `noite_iniciada` para saber quando lançar a próxima horda. Ele também armazena os multiplicadores que escalam dificuldade ao longo das ondas.

---

## Propriedades Principais

| Propriedade | Tipo | Descrição |
|-------------|------|-----------|
| `onda_atual` | `int` | Índice da onda corrente (global, incrementado pelo GM) |
| `modo_infinito` | `bool` | Ativa geração procedural após ondas pré-definidas |
| `multiplicador_horda` | `float` | Multiplica a quantidade de inimigos por onda |
| `multiplicador_velocidade_inimigo` | `float` | Escala a velocidade de todos os inimigos |

> ⚠️ `multiplicador_velocidade_inimigo` **não tem tipo declarado** — ao usar em GDScript com `:=` causa erro de inferência. Sempre usar `as float`.

---

## Sinais

```gdscript
signal noite_iniciada(numero_onda: int)
```

Emitido para iniciar uma nova noite/onda. Todos os spawners conectam a `_iniciar_noite(_n)`.

---

## Funções Críticas

### `registrar_spawner_concluido()`
Substitui o antigo `terminar_onda()`. Cada spawner chama essa função ao finalizar sua onda. O GameManager aguarda **todos** os spawners registrarem conclusão antes de avançar `onda_atual`.

```gdscript
# spawner_inimigos.gd
GameManager.registrar_spawner_concluido()
```

---

## Fluxo de Onda

```
GameManager.noite_iniciada.emit(n)
        │
        ▼
Spawner._iniciar_noite(n) ─── monta fila de inimigos
        │
        ▼
Timer → _spawnar_proximo() × N
        │
        ▼
_esperar_limpeza() → aguarda grupo "inimigos" vazio
        │
        ▼
GameManager.registrar_spawner_concluido()
        │
        ▼ (todos spawners concluíram)
GameManager avança onda_atual → emite noite_iniciada novamente
```

---

## Relações

- [[Sistemas/Ondas e Spawner]] — escuta `noite_iniciada`, chama `registrar_spawner_concluido`
- [[Código/spawner_inimigos.gd]] — implementação concreta que chama `registrar_spawner_concluido()`
- [[Sistemas/InimigoBase]] — lê `multiplicador_velocidade_inimigo`, `modo_infinito`
- [[Código/inimigo_base.gd]] — lê `multiplicador_velocidade_inimigo` diretamente no código
- [[Inimigos/HolandesVoador]] — lê `multiplicador_velocidade_inimigo as float` (ver bug abaixo)
- [[Código/holandes_voador.gd]] — local exato do bug de tipo (`as float`)
- [[Inimigos/Categorias de Inimigos]] — HP scaling por onda afeta todas as categorias
- [[Mapas/FendaDosPiratas]] — contexto de execução onde os multiplicadores são aplicados
- [[Referência Rápida — Bugs e Soluções]] — documenta o erro de tipo `multiplicador_velocidade_inimigo`

---

## ⚠️ Bugs Conhecidos / Armadilhas

### Tipo não declarado em `multiplicador_velocidade_inimigo`
```gdscript
# ❌ ERRO: Cannot infer the type of "vel"
var vel := velocidade * max(0.1, GameManager.multiplicador_velocidade_inimigo)

# ✅ CORRETO
var vel: float = velocidade * max(0.1, GameManager.multiplicador_velocidade_inimigo as float)
```

---

## Tags

`#sistema` `#singleton` `#ondas` `#dificuldade`
