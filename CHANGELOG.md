# Changelog

All notable changes to Prototype2 will be documented in this file.

## [0.1.7] - 2025-07-30
### Added - Hop 5: 6x6 Grid Battlefield System
- **BattleGrid**: Complete 6x6 grid battlefield system with 80x80 pixel tiles
- **Grid-based positioning**: Entities now spawn and position using grid coordinates
- **Team restrictions**: Allies spawn on left side (columns 0-2), enemies on right side (columns 3-5)
- **Multi-entity battles**: 2v2 battle configuration (2 Detectives vs 2 Imps)
- **Grid visualization**: Clear bold grid lines with team-color coding (green for allies, red for enemies)
- **Large entity support**: Framework for 2x2 entities (future implementation)
- **Unique entity naming**: Multiple entities of same type get distinct names (Detective, Detective_2, Imp, Imp_2)

### Changed
- **Project resolution**: Updated from 1280x720 to 1400x800 for better grid visibility
- **Entity scenes**: Converted from Node to Node2D root type for proper 2D positioning
- **Sprite scaling**: Normalized all entity sprites from 0.25 to 0.08 scale to fit grid tiles
- **EntitySpawner**: Enhanced with grid-aware positioning and multi-entity spawn support
- **BattleScene**: Updated to support 2v2 battles with proper team composition
- **CombatLog**: Improved display names using entity data instead of node names

### Fixed
- **Sprite visibility**: Entity sprites now properly visible on battlefield (Node2D positioning fix)
- **Combat log naming**: Shows proper entity names (Detective, Imp) instead of "Node"
- **Grid positioning**: Entities correctly placed within their assigned grid squares
- **Team separation**: Clear visual distinction between ally and enemy sides

### Technical
- **Grid system**: 480x480 pixel total grid (6x6 @ 80px each) centered on screen
- **Positioning**: Grid-to-pixel coordinate conversion with proper entity placement
- **Signal architecture**: Maintained existing BattleManager event system
- **Test coverage**: Added comprehensive grid functionality tests

## [0.1.6] - 2025-07-29
### Added
- Added **Shoot** ability to Detective by including it in `detective.tres`, now ActionBar shows three buttons: Shield, Regen, Shoot.
- Integration test `test_BattleScene_UI.gd` verifies 3 ability buttons and correct CombatLog entries.

### Changed
- Replaced deprecated `VBox`/`HBox` nodes with `VBoxContainer`/`HBoxContainer` in `ActionBar.tscn` and `CombatLog.tscn` for Godot 4 compatibility.
- Added `separation` property to ability button container and combat log container for uniform spacing.
- Modified `BattleManager.damage()` signature to include `attacker` parameter, ensuring CombatLog shows correct actor names.
- Updated `Entity.take_turn()` to pass `self` as attacker in damage calls.
- Fixed indentation and comment syntax in `theme_main.tres` (use `;` for comments), resolving theme load errors.
- Bootstrapped `CombatLog` UI in headless tests to display test messages.

### Fixed
- CombatLog entries no longer show "Unknown" actor; now correctly logs `Detective's turn begins` and damage events.
- UI spacing issue: Ability buttons now evenly spaced in the ActionBar.
- Theme parsing errors resolved, custom theme now loads without errors.

## [0.1.5] - 2025-07-28
- Initial release with basic combat framework, ActionBar, CombatLog, and unit portraits.
