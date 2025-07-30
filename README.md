# Prototype2

A tactical turn-based combat prototype built in Godot 4 featuring a 6x6 grid battlefield system. Core features:

## 🎮 **Core Systems**

- **BattleGrid**: 6x6 tactical grid battlefield with team-based positioning and visual grid lines
- **BattleScene**: Orchestrates multi-entity combat rounds and turns between teams
- **Entity**: Combatants with stats, abilities, portraits, and team-based logic
- **EntitySpawner**: Grid-aware entity placement with support for multi-entity battles
- **AbilityRegistry**: Auto-loads ability resources from `data/abilities` with metadata
- **AbilityContainer**: Resolves ability names into resources for UI display
- **ActionBar**: Shows entity abilities during turns with interactive buttons
- **CombatLog**: Scrollable event log with proper entity naming and combat events
- **UnitCard**: HUD panel displaying portrait, name, and health for active entity

## 🎯 **Current Features (v0.1.7)**

### Grid Battlefield System
- **6x6 grid**: 480x480 pixel battlefield with 80x80 pixel tiles
- **Team positioning**: Allies (left side) vs Enemies (right side) with color-coded areas
- **Multi-entity support**: 2v2 battles with proper team composition
- **Grid visualization**: Clear boundaries with team-specific coloring

### Combat System
- **Turn-based combat**: Proper initiative order and turn management
- **Multiple entity types**: Detective and Imp with unique abilities
- **Real-time feedback**: Combat log with meaningful entity names
- **Visual positioning**: Normalized sprite scaling for grid-based placement2

A side-view, turn-based combat prototype built in Godot 4. Core features:

- **BattleScene**: orchestrates rounds and turns between entities.
- **Entity**: represents combatants with stats, abilities, portraits, and logic.
- **AbilityRegistry**: auto-loads ability resources from `data/abilities`, exposing names and metadata.
- **AbilityContainer**: UI component that resolves ability names into resources and displays buttons.
- **ActionBar**: displays an entity’s abilities during their turn; buttons emit signals for execution.
- **CombatLog**: scrollable event log showing round starts, turns, damage, buffs, statuses, and battle end.
- **UnitCard**: HUD panel showing portrait, name, and health bar for the active entity.

## 🚀 **Getting Started**

1. **Requirements**
   - Godot Engine 4.5+
   - Linux, macOS, or Windows

2. **Running the Project**
   - Open this project in Godot
   - Ensure `AbilityReg`, `BuffReg`, and `StatusReg` are autoloaded (configured in `project.godot`)
   - Set the main scene to `res://scenes/battle/BattleScene.tscn` and run
   - Experience 2v2 tactical combat on the 6x6 grid

3. **Controls**
   - Click ability buttons during your turn to use abilities
   - Watch the combat log for battle events
   - Monitor entity health in the unit card

## 📁 **Directory Structure**

```
├── assets/              # Textures, themes, UI assets, entity sprites
├── data/               # Entity and ability resource definitions (.tres files)
├── scenes/             # Scene files (.tscn)
│   ├── battle/         # BattleScene, BattleGrid
│   ├── entities/       # Detective, Imp, EntityBase
│   └── ui/             # ActionBar, CombatLog, UnitCard, InitiativeBar
├── scripts/            # Game logic (GDScript)
│   ├── combat/         # BattleManager, Entity, EntitySpawner, BattleGrid
│   ├── ui/             # UI controllers and components
│   ├── registries/     # AbilityReg, BuffReg, StatusReg
│   └── resources/      # Custom resource definitions
└── test/               # GUT and integration tests
```

## 🔧 **Technical Highlights**

- **Grid-based positioning**: Pixel-perfect entity placement using coordinate conversion
- **Team restrictions**: Automatic side-based spawning with color-coded visual feedback
- **Multi-entity battles**: Support for NvN team compositions (currently 2v2)
- **Normalized sprites**: Consistent entity sizing across different texture dimensions
- **Signal-driven architecture**: Event-based UI updates and combat flow
- **Resource pipeline**: Data-driven abilities, buffs, and entity definitions

## 🧪 **Testing**

- **GUT integration**: Comprehensive test suite for core functionality
- **Integration tests**: Full battle scenario validation
- **Automated CI**: Headless testing support for continuous integration

## 🗺️ **Contributing**

- Follow the [scope and roadmap](roadmap.md) for planned features
- Add new abilities by creating `.tres` files under `data/abilities`
- Use Godot 4 container nodes (`HBoxContainer`/`VBoxContainer`) for UI
- Maintain signal-based architecture for UI updates
- Include tests for new functionality

## 📈 **Changelog**

See [CHANGELOG.md](CHANGELOG.md) for complete version history and feature documentation.

## 🎖️ **Project Status**

**Current Version**: 0.1.7 - Grid Battlefield System Complete  
**Next Milestone**: Enhanced tactical mechanics and larger battles  
**Engine**: Godot 4.5+ with Forward+ rendering
