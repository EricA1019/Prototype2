# Prototype2

A side-view, turn-based combat prototype built in Godot 4. Core features:

- **BattleScene**: orchestrates rounds and turns between entities.
- **Entity**: represents combatants with stats, abilities, portraits, and logic.
- **AbilityRegistry**: auto-loads ability resources from `data/abilities`, exposing names and metadata.
- **AbilityContainer**: UI component that resolves ability names into resources and displays buttons.
- **ActionBar**: displays an entity’s abilities during their turn; buttons emit signals for execution.
- **CombatLog**: scrollable event log showing round starts, turns, damage, buffs, statuses, and battle end.
- **UnitCard**: HUD panel showing portrait, name, and health bar for the active entity.

## Getting Started

1. **Requirements**
   - Godot Engine 4.5+
   - Linux, macOS, or Windows

2. **Running the Project**
   - Open this project in Godot.
   - Ensure `AbilityReg`, `BuffReg`, and `StatusReg` are autoloaded (configured in `project.godot`).
   - Set the main scene to `res://scenes/battle/BattleScene.tscn` and run.

3. **Directory Structure**
   - `assets/`: textures, themes, and UI assets.
   - `data/`: entity and ability resource definitions.
   - `scenes/`: all `.tscn` scene files (battle, UI, entities).
   - `scripts/`: game logic (combat, UI, registries, resources).
   - `test/`: GUT and integration tests for core functionality.

## Contributing

- Follow the [scope and roadmap](roadmap.md).
- Add new abilities by creating a `.tres` under `data/abilities` and update tests.
- Keep UI containers in Godot 4 (`HBoxContainer`/`VBoxContainer`) and use `separation` for spacing.
- Emit proper signals from `BattleManager` to drive UI updates.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
