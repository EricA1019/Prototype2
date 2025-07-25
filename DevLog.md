# Broken Divinity — Prototype MK2

## Dev Log 0.1.0 · 2025---

*End of Dev Log 0.1.0*

---

## Dev Log 0.1.1 · 2025‑07‑25

---

### ✨ Highlights

* **AbilityResource class loading FIXED** — resolved "Cannot get class 'AbilityResource'" errors in GUT tests
* **All GUT tests now PASSING** — registry successfully loads 4 ability .tres files (bleed, poison, shield, regen)
* **VS Code headless testing fully operational** — `Ctrl + Shift + B` runs complete test suite without errors
* **Resource architecture validated** — `.tres` files load correctly with proper script attachment

---

### 🔧 Technical Fixes Implemented

| Issue | Root Cause | Solution Applied |
|-------|------------|------------------|
| **Class Registration** | `AbilityResource` not available to ClassDB during headless runs | Added `@tool` annotation to register class at parse time |
| **Resource Type Conflicts** | `.tres` files using `type="AbilityResource"` before class registered | Modified generator to use `type="Resource"` with script attachment |
| **Global Class Registry** | Custom resource class not globally available | Added `AbilityResource` to `project.godot` global classes |
| **Test Type Safety** | `filter_by_tags()` expected `Array[String]` but received untyped array | Fixed test to use properly typed `Array[String]` parameter |

---

### ✅ Validated Functionality

| Component | Status | Test Coverage |
|-----------|--------|---------------|
| **AbilityResource.new()** | ✅ Working | Direct instantiation test passes |
| **Direct .tres loading** | ✅ Working | `load("res://data/abilities/bleed.tres")` succeeds |
| **Registry bootstrapping** | ✅ Working | Loads 4/4 ability files on startup |
| **Registry filtering** | ✅ Working | `filter_by_damage_type()` and `filter_by_tags()` functional |
| **GUT test suite** | ✅ Working | All tests pass in headless mode |

---

### 📁 Files Modified

* **`scripts/resources/AbilityResource.gd`** — Added `@tool` annotation for class registration
* **`project.godot`** — Added global class registry entry for `AbilityResource`
* **`generate_basic_abilities.py`** — Updated template to use `type="Resource"`
* **`data/abilities/*.tres`** — Regenerated with correct Resource type
* **`scenes/tests/test_AbilityReg.gd`** — Fixed typing issues in filter tests
* **`.vscode/tasks.json`** — Configured GUT headless execution via Flatpak

---

### 🎯 Architecture Validation

The **data-driven resource loading pipeline** is now fully operational:

1. **Class Registration** → `@tool` ensures `AbilityResource` available at parse time
2. **Resource Creation** → `.tres` files use base `Resource` type with script attachment
3. **Runtime Loading** → `ResourceLoader.load()` correctly instantiates typed resources
4. **Registry Integration** → `AbilityReg._scan_dir_recursive()` discovers and registers all abilities
5. **Test Coverage** → GUT validates entire pipeline from class creation to filtering

---

### 🔄 Next Development Phase

With the resource loading foundation **rock-solid**, the next milestone focuses on:

1. **Combat Logic Implementation**
   * Implement actual ability execution in `BattleManager`
   * Add damage calculation and status effect application
   * Wire buff/debuff tick logic for DOT/HOT effects

2. **Resource Content Expansion**
   * Create `BuffResource` and `StatusResource` classes
   * Generate complete ability/buff/status content libraries
   * Add icon assets and visual feedback systems

3. **Integration Testing**
   * End-to-end combat scenarios in GUT
   * Performance validation with larger resource sets
   * Memory leak detection during resource loading cycles

---

*End of Dev Log 0.1.1*‑25

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
