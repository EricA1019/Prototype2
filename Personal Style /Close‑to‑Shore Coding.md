# Broken Divinity — “Close‑to‑Shore Coding”

Personal engineering guide for how I want to build **Broken Divinity** quickly, safely, and with constant visible progress.

---

## 0. What “Close‑to‑Shore” Means

Sailors hugged the coastline to keep landmarks in sight and always have a safe harbor. I’ll do the same in code:

* **Short hops.** Each hop is a tiny vertical slice that *runs* end‑to‑end.
* **Always return to harbor.** End every hop with **green tests** and a **bootable scene**.
* **Never wander.** If a task expands, defer extras to the next hop.

**Parallels:** vertical slices / walking skeleton, TDD baby‑steps (red→green→refactor), trunk‑based development, continuous integration, small batch size.

---

## 1. Definition of Done (DoD)

A hop is done only when **all** of the following are true:

1. **GUT tests green** for the feature (plus `assert_no_new_orphans()`).
2. **TestHost scene boots headless** and executes the new behavior deterministically.
3. **Verbose logs** show clear, tagged steps (`[SystemTag]` prefix) with no noisy errors.
4. **Data‑driven**: no brittle hard‑coding; new content is found via folder scans or resources.
5. **Committed** to `main` (or a short branch merged immediately) with a crisp message.
6. **TODOs** added for deferred work inside files (future refinements / perf / UI polish).

---

## 2. Iteration Rhythm (Hops)

1. **Plan:** choose exactly one small vertical outcome (e.g., initiative bar shows correct order).
2. **Specify public API** first. No private poking in tests.
3. **Write tests** (unit first, then a small integration if needed).
4. **Implement minimal code** to satisfy tests.
5. **Refactor** only after green.
6. **Commit** and tag (`0.x.y`).

> *Rule of thumb:* a hop should be mergeable in ≤ 1–3 hours.

---

## 3. Testing Strategy

* **GUT everywhere.** Each feature ships with its own `test_*.gd` file.
* **Don’t show privates.** Tests hit only the public API.
* **Leak hygiene:** use `autoqfree`, `add_child_autoqfree`, and `assert_no_new_orphans()`.
* **Headless CI command:**

  ```bash
  godot4 --headless -s addons/gut/cli/gut_cmdln.gd \
    --path . -gdir=res://scenes/tests -ginclude_subdirs -gexit -glog=2
  ```
* **Integration smoke tests:** a short end‑to‑end run in `TestHost` proving the slice.

---

## 4. Godot Conventions

* **Engine:** Godot 4; **language:** GDScript first, C# only for perf‑hot loops later.
* **Autoload naming:** a `class_name` must not equal the autoload name. Use `AbilityRegistry` class, autoload **AbilityReg** (short **Reg** to avoid conflicts).
* **Resources over scenes** for data: `.tres` (`AbilityResource`, `BuffResource`, `StatusResource`, `StatBlockResource`, `EntityResource`).
* **Scanning content:** recursive loaders under `res://data/*`. Skip hidden & navigation entries. (We can migrate to `include_hidden` / `include_navigational` properties as we refine.)
* **Signals & EventBus:** prefer signals; route global events through an **EventBus** singleton for loose coupling.
* **Timers:** prefer `get_tree().create_timer()` for one‑shots; avoid persistent `Timer` nodes in tests.
* **Logs:** `[AbilityReg]`, `[BuffReg]`, `[StatusReg]`, `[CombatMgr]`, `[TurnMgr]`, `[UI]`.

---

## 5. Data‑Driven Rules

* **No hard‑wired content.** Abilities, buffs, statuses, entities are `.tres` files.
* **Names as keys.** Registries resolve by `resource_name`. UI auto‑populates from data (`AbilityContainer` → icons/buttons).
* **Damage types:** `Physical`, `Infernal`, `Holy` are first‑class. Keep a data table for modifiers.
* **Rounds vs Turns:** *Round* = everyone moves once; *Turn* = one unit acts. Buff/status expiry happens at **round end**.
* **Stacks:** buffs stack magnitude and extend duration (no global cap unless specified). Rare exceptions allowed (e.g., Unkillable).

---

## 6. File & Folder Layout (core)

```
data/
  abilities/    # AbilityResource .tres
  buffs/        # BuffResource .tres
  statuses/     # StatusResource .tres
  entities/
    statblocks/ # StatBlockResource .tres
scripts/
  registries/   # *Reg.gd singletons
  combat/       # BattleManager, TurnManager, Entity, AbilityContainer
  resources/    # *Resource.gd classes
  systems/      # EventBus, DamageTable, logging helpers
  ui/           # UI widgets (InitiativeBar, Panels, ActionBar, Log)
scenes/
  entities/     # EntityBase.tscn
  tests/        # TestHost.tscn + GUT tests
```

---

## 7. Git & VS Code

* **Short branches**, merge fast. Main stays green/bootable.
* **Tasks:**

  * **All tests:** `GUT: all` → headless command above.
  * **UI slice tests:** target `scenes/tests/ui` for fast feedback.
* **PATH:** `godot4` wrapper pointing at the current Desktop build via `~/.local/bin/godot4` symlink.

---

## 8. Prompting LLMs (house style)

**Goal:** get deterministic, runnable scaffolds with tests and clear choices.

### When asking

* State **engine version**, **language**, and **Godot 4** specifics.
* Provide **file paths** and **autoload names**.
* Specify **public API** you want (methods, signals, return types).
* Ask for **GUT tests first**, then implementation.
* Emphasize **data‑driven** and **headless** requirements.
* Request **verbose logging** and `TODO` markers.
* Prefer **single Python bootstrap scripts** that write files and skip existing ones.

### Template prompt

```
I’m using Godot 4 (GDScript). Create a vertical slice with GUT tests.

Constraints:
- Public API only; tests must not access privates.
- Data-driven: load .tres resources from res://data/* recursively.
- Autoload names differ from class_name (e.g., AbilityReg autoload, AbilityRegistry class).
- Provide verbose [SystemTag] logging and TODO markers.
- Headless runnable: include a GUT test and a minimal TestHost scene if needed.
- Provide a Python script to create folders and files; skip existing.

Deliver:
1) Tests in res://scenes/tests/test_Feature.gd
2) Implementation files under the specified paths
3) Any generators for .tres with correct [ext_resource]/[resource] blocks.
```

### Review checklist for LLM outputs

* Do tests use **`autoqfree`** and **`assert_no_new_orphans()`**?
* Are `.tres` headers valid (`[ext_resource]` + `[resource]`)?
* Are arrays typed **only where safe**? (Prefer untyped `Array` for registry keys.)
* Are directory scans **recursive** and skipping hidden/nav?
* Are log prefixes consistent?

---

## 9. Next UI Hops (tracked)

1. **Initiative bar** auto‑populates from TurnManager order.
2. **Entity panels**: name + HP, update on `hp_changed`/`died`.
3. **Action bar** from `AbilityContainer`, click handlers only call public API.
4. **Combat log** via EventBus.
5. **Victory banner** at `battle_ended`.

Each hop: tests → run headless → commit.

---

## 10. Personal guardrails

* Prefer **clarity over cleverness**. Small, boring code that’s easy to test.
* If a function exceeds \~30–40 lines, consider splitting after the hop.
* Add `TODO:` with a tag (`perf`, `ui`, `balance`, `refactor`) for quick grepping.
* When in doubt, **log it**.

---

*Living document — update as habits evolve.*
