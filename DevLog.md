# Broken Divinity — Prototype MK2

## Dev Log 0.1.7 · 2025-07-30

### 🎯 **Hop 5 Complete: 6x6 Grid Battlefield**

**Major milestone achieved!** Complete implementation of the tactical grid battlefield system.

### ✨ Highlights

* **6x6 Grid System** — 480x480 pixel battlefield with 80x80 pixel tiles
* **Team-based positioning** — Allies (columns 0-2) vs Enemies (columns 3-5) with color-coded grid lines
* **2v2 Battle Support** — Multi-entity battles with proper team composition (2 Detectives vs 2 Imps)
* **Grid-aware Entity Spawning** — EntitySpawner now places entities using grid coordinates
* **Normalized Sprite Scaling** — All entity sprites properly sized to fit within grid tiles
* **Enhanced Combat Logging** — Proper entity names in combat log instead of "Node" references

### 🔧 Technical Implementations

| Component | Implementation | Status |
|-----------|---------------|---------|
| **BattleGrid** | 6x6 grid system with team restrictions | ✅ Complete |
| **Grid Positioning** | Pixel-perfect entity placement | ✅ Complete |
| **Multi-entity Spawning** | 2v2 battle configuration | ✅ Complete |
| **Visual Grid Lines** | Team-colored boundaries | ✅ Complete |
| **Sprite Normalization** | 0.08 scale for 60px sprites in 80px tiles | ✅ Complete |
| **Entity Naming** | Unique names for multiple same-type entities | ✅ Complete |

### 🎮 **Player Experience**

* **Clear battlefield layout** with visible grid structure
* **Distinct team sides** with color-coded grid areas
* **Properly sized sprites** that fit comfortably within grid squares
* **Readable combat log** with meaningful entity names
* **Smooth 2v2 combat** with proper turn order

### 📐 **Grid Specifications**

* **Grid Size**: 6x6 tiles (30 squares total)
* **Tile Size**: 80x80 pixels each
* **Total Battlefield**: 480x480 pixels
* **Team Areas**: 3 columns per team (18 squares each)
* **Entity Scale**: 0.08 (approximately 60px sprites)
* **Resolution**: 1400x800 (updated for better grid visibility)

*End of Dev Log 0.1.7*

---

## Dev Log 0.1.0 · 2025---

*End of Dev Log 0.1.0*ken Divinity — Prototype MK2

## Dev Log 0.1.0 · 2025---

*End of Dev Log 0.1.0*

---

## Dev Log 0.1.2 · 2025-07-26

### ✨ Highlights

* **BattleManager: configurable max_rounds** — cap infinite loops in turn-based combat
* **BattleManager: filter dead units** — get_enemies now ignores units with hp ≤ 0
* **Test suite expanded** — updated tests to include max_rounds cap; all 19 GUT tests passing

*End of Dev Log 0.1.2*

## Dev Log 0.1.3 · 2025-07-26

### ✨ Highlights

* **Spawner refactored** — EntitySpawner now auto-loads base EntityScene by default.
* **UI improvements** — InitiativeBar signal binding and error handling tightened.
* **Version bump** — project updated to 0.1.3.

*End of Dev Log 0.1.3*

## Dev Log 0.1.1 · 2025-07-25

---

### ✨ Highlights

* **Complete registry system implementation** — AbilityReg, BuffReg, and StatusReg all fully functional
* **StatusReg system delivered** — status effects (Stunned, Guarded, Marked, Channeling) with proper turn blocking, duration management, and tag-based clearing
* **16/16 GUT tests passing** — comprehensive test coverage across all three registry systems
* **Zero resource leaks** — clean memory management with proper cleanup methods
* **Data-driven resource pipeline** — all .tres files loading correctly with proper script attachment

---

### 🔧 Technical Implementations Completed

| System | Features Implemented | Test Coverage |
|--------|---------------------|---------------|
| **AbilityReg** | Resource loading, filtering by damage type/tags, cleanup | 6/6 tests ✅ |
| **BuffReg** | DOT/HOT mechanics, stacking, duration management, cleansing | 4/4 tests ✅ |
| **StatusReg** | Status application, turn blocking, expiration, tag clearing | 5/5 tests ✅ |
| **BattleManager** | Round counter, clean node management | 1/1 test ✅ |

---

### 🎯 StatusReg Architecture

The **StatusReg** system provides comprehensive status effect management:

1. **Status Application** → `apply_status()` with stacking rules and duration override support
2. **Turn Blocking** → `blocks_turn()` queries `affects_turn` and `blocks_actions` properties
3. **Duration Management** → `on_round_end()` decrements durations and expires statuses
4. **Tag-based Clearing** → `clear_by_tags()` removes statuses by category (Control, Debuff, etc.)
5. **Clean Resource Tracking** → Instance ID-based storage with proper cleanup

---

### ✅ Resource Content Library

| Category | Resources Implemented | Properties |
|----------|----------------------|------------|
| **Abilities** | Bleed, Poison, Shield, Regen | Damage types, tag filtering, magnitudes |
| **Buffs** | Bleed, Poison, Shield, Regen | DOT/HOT mechanics, stacking, magnitude scaling |
| **Statuses** | Stunned, Guarded, Marked, Channeling | Turn blocking, action prevention, duration timers |

---

### 🔧 Critical Fixes Applied

| Issue | Root Cause | Solution |
|-------|------------|----------|
| **Resource Leaks** | BattleManager Node not freed after tests | Added `queue_free()` to test cleanup |
| **Class Name Conflicts** | `StatusReg` class name hiding autoload | Removed conflicting class_name declaration |
| **Type Annotation Errors** | StatusResource type not globally available | Updated to use base Resource type |
| **API Parameter Conflicts** | Function params named `name` shadow Node.name | Renamed to `status_name` throughout |

---

### 📁 Files Modified/Created

* **`scripts/registries/StatusReg.gd`** — Complete implementation with turn blocking and duration management
* **`scripts/resources/StatusResource.gd`** — Status definition resource with behavior flags
* **`data/statuses/*.tres`** — Four status definitions (Stunned, Guarded, Marked, Channeling)
* **`scenes/tests/test_StatusReg.gd`** — Comprehensive test suite for status system
* **`project.godot`** — Added StatusResource to global classes, StatusReg autoload
* **Various registry files** — Added cleanup methods to prevent resource leaks

---

### 🎯 Architecture Validation

The **complete registry ecosystem** is now operational:

1. **Data-Driven Loading** → All three registries scan their respective directories recursively
2. **Resource Type Safety** → Proper .tres file format with script attachment
3. **Memory Management** → Zero leaks with comprehensive cleanup methods
4. **Test Coverage** → 16 tests validating core functionality across all systems
5. **Integration Ready** → All registries ready for BattleManager integration

---

### 🔄 Next Development Phase

With the **foundation systems complete**, next priorities are:

1. **Combat Integration**
   * Integrate registries with BattleManager for actual combat execution
   * Implement ability activation with status/buff application
   * Add damage calculation and HP modification

2. **UI Integration**
   * Status effect indicator displays
   * Buff/debuff visual feedback
   * Turn order visualization with status indicators

3. **Content Expansion**
   * Additional abilities with varied effects
   * More complex status interactions
   * Balanced magnitude and duration values

---

*End of Dev Log 0.1.1*
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
