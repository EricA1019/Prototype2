# Changelog

All notable changes to Prototype2 will be documented in this file.

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
