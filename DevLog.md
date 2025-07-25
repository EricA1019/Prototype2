# Broken Divinity — Prototype MK2

## Dev Log 0.1.0 · 2025‑07‑25

---

### ✨ Highlights

* **Project scaffolded automatically** with `setup_broken_divinity.py`
  → Generates folder tree, registry/combat stubs, headless test scene, & GUT test suite.
* **Data‑driven architecture locked in** — registries recurse through `data/*` folders at startup.
* **VS Code workspace configured** for one‑key **headless test runs** (`Ctrl + Shift + B`) and direct launch into `BattleTestScene`.

---

### ✔️ Implemented in 0.1.0

| Area             | Work Completed                                                                                                  |
| ---------------- | --------------------------------------------------------------------------------------------------------------- |
| **Folders**      | `data/abilities`, `data/buffs`, `data/statuses`, `scripts/registries`, `scripts/combat`, `scenes/tests`         |
| **Core Scripts** | `AbilityReg.gd`, `BuffReg.gd`, `StatusReg.gd`, `BattleManager.gd` (all stubbed with public APIs & TODO markers) |
| **Test Scene**   | `BattleTestScene.tscn` boots BattleManager headless for log‑only rounds                                         |
| **GUT Suite**    | `test_AbilityReg.gd`, `test_BuffReg.gd`, `test_BattleManager.gd` — all discovered via *test\_*.gd convention    |
| **Logging**      | Standardised `[SystemTag]` prefixes across stubs                                                                |

---

### 🔄 In‑Flight / Next Milestones

1. **Complete recursive loaders**

   * Finish `.tres` scanning logic in `BuffReg` and `StatusReg` (AbilityReg already demoed).
2. **Create first playable resources**

   * Abilities → *Strike*, *Heal*, *Smite* (Physical / Holy / Infernal).
   * Buffs → *Poison*, *Bleed*, *Shield*, *Regen*.
3. **Implement Unit class & basic AI**

   * Random valid ability selection; speed stat injected for initiative queue.
4. **Round‑end buff ticking**

   * Stack magnitude + refresh duration; expire & emit signal `buff_expired(unit, buff_name)`.
5. **Placeholder UI pass**

   * Initiative portrait bar and auto‑populated ability bar using `Resource.portrait_path`.
6. **Smoke integration test**

   * End‑to‑end GUT script that runs `BattleManager` for three rounds and asserts correct HP deltas & buff expiry.

---

### 🗒 Notes & TODO Markers

* **Performance** — revisit C# for tight loops once baseline gameplay is fun.
* **Logging** — wire to planned `LogRelay` singleton when ready.
* **Recursive scanning** — ignore hidden (`.`) and backup (`~`) files.
* **Versioning** — tag GitHub release **0.1.0** after committing scaffold; bump to **0.1.1** when first ability executes successfully.

---

*End of Dev Log 0.1.0*
\#EOF
