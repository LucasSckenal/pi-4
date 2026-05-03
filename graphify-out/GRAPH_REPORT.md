# Graph Report - Obsidian Vault  (2026-05-03)

## Corpus Check
- Corpus is ~8,003 words - fits in a single context window. You may not need a graph.

## Summary
- 15 nodes · 82 edges · 2 communities detected
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Sistemas e Código GDScript|Sistemas e Código GDScript]]
- [[_COMMUNITY_Boss, Mapa e Efeitos Visuais|Boss, Mapa e Efeitos Visuais]]

## God Nodes (most connected - your core abstractions)
1. `Index â€” Wiki Principal` - 14 edges
2. `ReferÃªncia RÃ¡pida â€” Bugs e SoluÃ§Ãµes` - 14 edges
3. `HolandÃªs Voador` - 14 edges
4. `Fenda dos Piratas` - 14 edges
5. `inimigo_base.gd` - 12 edges
6. `spawner_inimigos.gd` - 12 edges
7. `InimigoBase` - 12 edges
8. `holandes_voador.gd` - 11 edges
9. `Categorias de Inimigos` - 11 edges
10. `Ondas e Spawner` - 11 edges

## Surprising Connections (you probably didn't know these)
- `ReferÃªncia RÃ¡pida â€” Bugs e SoluÃ§Ãµes` --rationale_for--> `NavegaÃ§Ã£o e Movimento`  [INFERRED]
  Obsidian Vault/ReferÃªncia RÃ¡pida â€” Bugs e SoluÃ§Ãµes.md → Obsidian Vault/Sistemas/NavegaÃ§Ã£o e Movimento.md
- `HolandÃªs Voador` --conceptually_related_to--> `InimigoBase`  [INFERRED]
  Obsidian Vault/Inimigos/HolandesVoador.md → Obsidian Vault/Sistemas/InimigoBase.md
- `Index â€” Wiki Principal` --references--> `GameManager`  [EXTRACTED]
  Obsidian Vault/Index.md → Obsidian Vault/Sistemas/GameManager.md
- `Index â€” Wiki Principal` --references--> `Ondas e Spawner`  [EXTRACTED]
  Obsidian Vault/Index.md → Obsidian Vault/Sistemas/Ondas e Spawner.md
- `Index â€” Wiki Principal` --references--> `InimigoBase`  [EXTRACTED]
  Obsidian Vault/Index.md → Obsidian Vault/Sistemas/InimigoBase.md

## Hyperedges (group relationships)
- **Ciclo de Vida de Onda** — sistemas_gamemanager, sistemas_ondas_spawner, codigo_spawner_inimigos_gd, sistemas_inimigobase [EXTRACTED 0.95]
- **Pipeline de Spawn do Boss** — codigo_spawner_inimigos_gd, inimigos_holandes_voador, codigo_holandes_voador_gd, sistemas_navegacao_movimento [INFERRED 0.88]
- **Ecossistema da Fenda dos Piratas** — mapas_fenda_dos_piratas, inimigos_holandes_voador, codigo_bolhas_gdshader, sistemas_shaders_efeitos, codigo_spawner_inimigos_gd [EXTRACTED 0.92]
- **Cluster de Bugs de NavegaÃ§Ã£o** — bugs_referencia_rapida, sistemas_navegacao_movimento, codigo_inimigo_base_gd, codigo_holandes_voador_gd, codigo_spawner_inimigos_gd [EXTRACTED 0.90]
- **ImplementaÃ§Ãµes de InimigoBase** — sistemas_inimigobase, codigo_inimigo_base_gd, inimigos_holandes_voador, codigo_holandes_voador_gd, inimigos_categorias [EXTRACTED 0.95]

## Communities (2 total, 0 thin omitted)

### Community 0 - "Sistemas e Código GDScript"
Cohesion: 0.86
Nodes (9): holandes_voador.gd, inimigo_base.gd, spawner_inimigos.gd, Categorias de Inimigos, GameManager, InimigoBase, NavegaÃ§Ã£o e Movimento, Ondas e Spawner (+1 more)

### Community 1 - "Boss, Mapa e Efeitos Visuais"
Cohesion: 1.0
Nodes (6): ReferÃªncia RÃ¡pida â€” Bugs e SoluÃ§Ãµes, Bolhas.gdshader, Index â€” Wiki Principal, HolandÃªs Voador, Fenda dos Piratas, Shaders e Efeitos Visuais

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Index â€” Wiki Principal` connect `Boss, Mapa e Efeitos Visuais` to `Sistemas e Código GDScript`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `ReferÃªncia RÃ¡pida â€” Bugs e SoluÃ§Ãµes` connect `Boss, Mapa e Efeitos Visuais` to `Sistemas e Código GDScript`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `HolandÃªs Voador` connect `Boss, Mapa e Efeitos Visuais` to `Sistemas e Código GDScript`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._