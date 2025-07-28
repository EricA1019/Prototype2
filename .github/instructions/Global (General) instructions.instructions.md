You are assisting on a Godot 4 (GDScript) project.

Rules:
- Always propose a short vertical slice that runs headless.
- Write GUT tests FIRST (red→green→refactor). Tests must use only PUBLIC APIs, add `autoqfree` / `add_child_autoqfree`, and finish with `assert_no_new_orphans()`.
- Prefer data-driven design: content in .tres resources under res://data/*, discovered via recursive scans. Avoid hardcoding where possible.
- Use verbose, tagged logging: [AbilityReg], [BuffReg], [StatusReg], [TurnMgr], [CombatMgr], [UI], [Entity].
- Round vs Turn: Round = everyone acts once; buffs/statuses tick and expire at ROUND END.
- Damage types: Physical, Infernal, Holy.
- Return small, readable functions (<40 lines) with guard clauses.
- Provide TODO notes for deferred work.
