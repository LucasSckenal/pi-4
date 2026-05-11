---
type: community
cohesion: 0.32
members: 12
---

# Sistema de Build e Upgrade

**Cohesion:** 0.32 - loosely connected
**Members:** 12 nodes

## Members
- [[BuildSlot]] - code - Scripts Locais/build_slot.gd
- [[BuildSlotManager]] - code - Scripts Globais/BuildSlotManager.gd
- [[BuildingMine]] - code - Scripts Locais/building_mine.gd
- [[Builds (Node3D)]] - code - Scripts Globais/Builds.gd
- [[CartaUI (Button)]] - code - Scripts Locais/carta_ui.gd
- [[CartaUpgrade]] - code - PowerUps/carta_upgrade.gd
- [[ConselheiroIA]] - code - Scripts Globais/conselheiro_ia.gd
- [[EnemyIcon (HUD Indicator)]] - code - Scripts Locais/enemy_icon.gd
- [[GameManager (Autoload)]] - code - Scripts Globais/game_manager.gd
- [[HUD (CanvasLayer)]] - code - Scripts Locais/hud.gd
- [[LevelLightningController]] - code - Scripts Locais/level_lightning_controller.gd
- [[UpgradePathData (Resource)]] - code - Scripts Globais/Builds.gd

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Sistema_de_Build_e_Upgrade
SORT file.name ASC
```

## Connections to other communities
- 4 edges to [[_COMMUNITY_Gameplay e Estrutura de Mapa]]
- 2 edges to [[_COMMUNITY_Menus, Player e Efeitos Visuais]]
- 1 edge to [[_COMMUNITY_Autoloads e Sistema Global]]

## Top bridge nodes
- [[GameManager (Autoload)]] - degree 11, connects to 2 communities
- [[Builds (Node3D)]] - degree 10, connects to 1 community
- [[HUD (CanvasLayer)]] - degree 7, connects to 1 community
- [[BuildingMine]] - degree 2, connects to 1 community
- [[UpgradePathData (Resource)]] - degree 2, connects to 1 community