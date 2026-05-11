# Graph Report - .  (2026-05-03)

## Corpus Check
- Large corpus: 396 files · ~10,883,289 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 113 nodes · 346 edges · 17 communities detected
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 38 edges (avg confidence: 0.79)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Bugs, Docs e Referência|Bugs, Docs e Referência]]
- [[_COMMUNITY_Autoloads e Sistema Global|Autoloads e Sistema Global]]
- [[_COMMUNITY_Gameplay e Estrutura de Mapa|Gameplay e Estrutura de Mapa]]
- [[_COMMUNITY_Menus, Player e Efeitos Visuais|Menus, Player e Efeitos Visuais]]
- [[_COMMUNITY_Boss, Spawner e Vault Core|Boss, Spawner e Vault Core]]
- [[_COMMUNITY_Sistema de Build e Upgrade|Sistema de Build e Upgrade]]
- [[_COMMUNITY_Navegação e InimigoBase|Navegação e InimigoBase]]
- [[_COMMUNITY_Outline Shaders|Outline Shaders]]
- [[_COMMUNITY_Water Shaders|Water Shaders]]
- [[_COMMUNITY_WaveData e InimigoConfig|WaveData e InimigoConfig]]
- [[_COMMUNITY_CameraFollow|CameraFollow]]
- [[_COMMUNITY_Configurações|Configurações]]
- [[_COMMUNITY_Dummy Target|Dummy Target]]
- [[_COMMUNITY_Onde Estão os Netos|Onde Estão os Netos?]]
- [[_COMMUNITY_CursorManager|CursorManager]]
- [[_COMMUNITY_Camera3D|Camera3D]]
- [[_COMMUNITY_Canto|Canto]]

## God Nodes (most connected - your core abstractions)
1. `Referência Rápida — Bugs e Soluções` - 26 edges
2. `inimigo_base.gd` - 24 edges
3. `spawner_inimigos.gd` - 24 edges
4. `GameManager` - 24 edges
5. `holandes_voador.gd` - 22 edges
6. `Fenda dos Piratas` - 21 edges
7. `holandes_voador.gd` - 20 edges
8. `Holandês Voador (Boss)` - 19 edges
9. `inimigo_base.gd` - 19 edges
10. `InimigoBase` - 16 edges

## Surprising Connections (you probably didn't know these)
- `Builds (Node3D)` --conceptually_related_to--> `Castle (Castelo)`  [INFERRED]
  Scripts Globais/Builds.gd → Scripts Locais/castle.gd
- `Opcao Upgrade Button` --conceptually_related_to--> `GameManager`  [INFERRED]
  Scripts Locais/opcao_upgrade_button.gd → Obsidian Vault/GameManager.md
- `BuildingMine` --calls--> `Balanceamento (Autoload)`  [EXTRACTED]
  Scripts Locais/building_mine.gd → Scripts Globais/Balanceamento.gd
- `Upgrade UI (Upgrade Panel)` --uses--> `UpgradePathData (Resource)`  [INFERRED]
  UI/Upgrade/upgrade_ui.gd → Scripts Globais/Builds.gd
- `Bolhas Shader (Bubble/Underwater Screen Effect)` --conceptually_related_to--> `Orc (Enemy)`  [INFERRED]
  Shaders/Bolhas.gdshader → Scripts Locais/orc.gd

## Hyperedges (group relationships)
- **Ecossistema da Fenda dos Piratas** — mapas_fenda_dos_piratas, inimigos_holandes_voador, codigo_bolhas_gdshader, sistemas_shaders_efeitos, codigo_spawner_inimigos_gd [EXTRACTED 0.92]
- **Ciclo de Vida de Onda** — sistemas_gamemanager, sistemas_ondas_spawner, codigo_spawner_inimigos_gd, sistemas_inimigobase [EXTRACTED 0.95]
- **ImplementaÃ§Ãµes de InimigoBase** — sistemas_inimigobase, codigo_inimigo_base_gd, inimigos_holandes_voador, codigo_holandes_voador_gd, inimigos_categorias [EXTRACTED 0.95]
- **Ciclo de Vida de Onda** — sistemas_gamemanager, sistemas_ondas_spawner, codigo_spawner_inimigos_gd, sistemas_inimigobase [EXTRACTED 0.95]
- **Pipeline de Spawn do Boss** — codigo_spawner_inimigos_gd, inimigos_holandes_voador, codigo_holandes_voador_gd, sistemas_navegacao_movimento [INFERRED 0.88]
- **Ecossistema da Fenda dos Piratas** — mapas_fenda_dos_piratas, inimigos_holandes_voador, codigo_bolhas_gdshader, sistemas_shaders_efeitos, codigo_spawner_inimigos_gd [EXTRACTED 0.92]
- **Cluster de Bugs de Navegação** — bugs_referencia_rapida, sistemas_navegacao_movimento, codigo_inimigo_base_gd, codigo_holandes_voador_gd, codigo_spawner_inimigos_gd [EXTRACTED 0.90]
- **Implementações de InimigoBase** — sistemas_inimigobase, codigo_inimigo_base_gd, inimigos_holandes_voador, codigo_holandes_voador_gd, inimigos_categorias [EXTRACTED 0.95]
- **Enemy Script + Concept + Category Cluster** — inimigo_base_gd_script, inimigobase_concept, categorias_de_inimigos_categorias, holandes_voador_gd_script, holandes_voador_concept [INFERRED 0.85]
- **Spawn Timing + Navigation Bug Chain** — spawner_inimigos_gd_script, bug_inimigo_parado_spawn, navegacao_e_movimento_concept, holandes_voador_gd_script [EXTRACTED 0.95]
- **Fenda dos Piratas Visual and Boss Cluster** — fenda_dos_piratas_fenda, bolhas_gdshader_bolhasgdshader, shaders_efeitos_visuais_concept, holandes_voador_concept [EXTRACTED 0.90]
- **Day/Night Cycle Pipeline** — game_manager_gamemanager, build_slot_buildslot, builds_builds, hud_hud, level_lightning_controller_levellightningcontroller [EXTRACTED 1.00]
- **Build and Upgrade System** — game_manager_gamemanager, builds_builds, build_slot_buildslot, buildslotmanager_buildslotmanager, carta_upgrade_cartaupgrade, carta_ui_cartaui, hud_hud [EXTRACTED 0.95]
- **CSV Balanceamento Hot-Reload Pipeline** — balanceamento_balanceamento, game_manager_gamemanager, builds_builds, castle_castle, building_mine_buildingmine [EXTRACTED 1.00]
- **Combat Units (Player, Soldier, Orc, Tower, Torre de Fogo)** — player_player, soldier_soldier, orc_orc, tower_tower, torre_de_fogo_torrefogo [INFERRED 0.85]
- **Passive Income Buildings (House, Mill)** — unit_house_2_unithouse, unit_mill_2_unitmill [EXTRACTED 1.00]
- **Fortification Structures (Wall, Wall 2, Wall Gate 2)** — walls_word_1_wall, wall_2_wall2, wall_gate_2_wallgate2 [INFERRED 0.85]
- **End-Game Flow: Victory, GameOver and GameManager** — tela_vitoria_script, game_over_ui_script, autoload_gamemanager [EXTRACTED 1.00]
- **Water Shader Family (toon-style water effects)** — water_shader, waterflat_shader, lava_shader [INFERRED 0.75]
- **Level Selection Flow: Selector, Modal, GameManager** — seletor_fases_script, modal_modo_fase_modalmodofase, autoload_gamemanager [EXTRACTED 1.00]

## Communities (17 total, 10 thin omitted)

### Community 0 - "Bugs, Docs e Referência"
Cohesion: 0.43
Nodes (23): Bolhas.gdshader, Bug: ColorRect de shader bloqueia cliques, Bug: Inimigo parado ao spawnar, Bug: Inimigos não encontram a base (Fenda dos Piratas), Bug: Boss executa teleporte múltiplas vezes, Bug: Boss não tem candidatos para teleporte, Bug: Inimigo teleporta para origem (0,0,0), Categorias de Inimigos (+15 more)

### Community 1 - "Autoloads e Sistema Global"
Cohesion: 0.14
Nodes (17): GameManager (Autoload), Global (Autoload), MusicaGlobal (Autoload), ConquistaData Resource, ConselheiroIA (AI Advisor Logic), Controles Mobile HUD, Game Over UI, Lava Shader (+9 more)

### Community 2 - "Gameplay e Estrutura de Mapa"
Cohesion: 0.23
Nodes (15): Balanceamento (Autoload), Bolhas Shader (Bubble/Underwater Screen Effect), Bug: Erro de tipo ao ler GameManager, Castle (Castelo), Energy Material Shader (Flame/Glow Energy Effect), GameManager, Opcao Upgrade Button, Orc (Enemy) (+7 more)

### Community 3 - "Menus, Player e Efeitos Visuais"
Cohesion: 0.21
Nodes (15): ConquistaData (Resource), Dithering Effect Shader (Bayer Matrix Transparency), Global (Autoload), Highlight Shader (Shield/Fresnel Unit Highlight), Main Menu, Musica Global (Audio Autoload), Outline Shader (Character Outline), Player (Hero Character) (+7 more)

### Community 4 - "Boss, Spawner e Vault Core"
Cohesion: 0.85
Nodes (14): Referência Rápida — Bugs e Soluções, holandes_voador.gd, inimigo_base.gd, spawner_inimigos.gd, Index â€” Wiki Principal, Categorias de Inimigos, HolandÃªs Voador, Fenda dos Piratas (+6 more)

### Community 5 - "Sistema de Build e Upgrade"
Cohesion: 0.32
Nodes (12): BuildSlot, BuildingMine, Builds (Node3D), BuildSlotManager, CartaUI (Button), CartaUpgrade, ConselheiroIA, EnemyIcon (HUD Indicator) (+4 more)

### Community 6 - "Navegação e InimigoBase"
Cohesion: 0.5
Nodes (4): HolandesVoador (referenced), InimigoBase (referenced), Navegação e Movimento (Doc), NavigationAgent3D System

## Knowledge Gaps
- **33 isolated node(s):** `Onde Estão os Netos? (Game)`, `BuildSlotManager`, `CursorManager (Autoload)`, `PopupConquista`, `Camera3D (Spinning)` (+28 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GameManager` connect `Gameplay e Estrutura de Mapa` to `Bugs, Docs e Referência`, `Menus, Player e Efeitos Visuais`, `Boss, Spawner e Vault Core`?**
  _High betweenness centrality (0.387) - this node is a cross-community bridge._
- **Why does `Builds (Node3D)` connect `Sistema de Build e Upgrade` to `Gameplay e Estrutura de Mapa`?**
  _High betweenness centrality (0.240) - this node is a cross-community bridge._
- **Why does `Balanceamento (Autoload)` connect `Gameplay e Estrutura de Mapa` to `Sistema de Build e Upgrade`?**
  _High betweenness centrality (0.226) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `GameManager` (e.g. with `Ondas e Spawner` and `Orc (Enemy)`) actually correct?**
  _`GameManager` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `holandes_voador.gd` (e.g. with `InimigoBase` and `holandes_voador.gd`) actually correct?**
  _`holandes_voador.gd` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Onde Estão os Netos? (Game)`, `BuildSlotManager`, `CursorManager (Autoload)` to the rest of the system?**
  _33 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Autoloads e Sistema Global` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._