Project: Broken Divinity — Prototype MK2 (Godot 4, GDScript).

Architecture:
- Registries as autoloads: AbilityReg, BuffReg, StatusReg, EventBus. Class names differ from autoload names (e.g., AbilityRegistry vs AbilityReg).
- Managers as scene nodes: BattleManager (owns TurnManager), not autoloads.
- Entities use EntityResource + StatBlockResource; abilities are resolved via AbilityReg; starting buffs/statuses applied via registries.
- UI must auto-populate from data. Use structured containers (InitiativeBar, ActionBar, EntityPanel, CombatLog).

Delivery pattern:
1) GUT tests in res://scenes/tests/**  (test_*.gd).
2) Implementation code under scripts/** and scenes/**.
3) If content files are needed, include a Python generator that writes correct Godot 4 .tres ([ext_resource]/[resource]).
4) Provide a headless command I can paste into a VS Code task:
   godot4 --headless -s addons/gut/cli/gut_cmdln.gd --path . -gdir=res://scenes/tests -ginclude_subdirs -gexit -glog=2

Preference:
- Lots of print() for step-by-step tracing.
- Use untyped Array for registry key returns to avoid typed-array friction.
