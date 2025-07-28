# Personal Style / Preferences

A concise reference for how I like to structure code, tests, logs, and UI in **Broken Divinity**.

---

## Core values

* **Lots of prints.** Verbose, tagged console output so I can trace the whole flow quickly.
* **Data‑driven first.** Content lives in `.tres` resources (or JSON for pure text). Systems *discover* content by scanning folders.
* **Avoid hard‑coding.** Some glue is inevitable, but prefer tables, maps, and registries over `if/elif` ladders.
* **Auto‑populating UI.** The UI should “just work”: containers read data and spawn the right controls (no static, hand‑placed button sets).
* **Short hops, always green.** End every change with passing tests and a bootable scene (see Close‑to‑Shore guide).

---

## Logging style

* Prefix every subsystem with a bracketed tag.

  * `[AbilityReg]`, `[BuffReg]`, `[StatusReg]`, `[TurnMgr]`, `[CombatMgr]`, `[UI]`, `[Entity]`.
* Use concise messages that include the important parameters, e.g.:

  * `[BuffReg] Applied Poison to <Entity#42> → stacks=2 dur=6 mag=8`
  * `[TurnMgr] Start: f1,f2,e1,e2 (spd 12,11,10,8)`
* **Never silently fail.** Use `push_warning`/`push_error` for exceptional conditions.
* TODO markers inline where appropriate: `# TODO(perf): cache lookups`.

### Tiny helper (optional)

```gdscript
# scripts/systems/Log.gd
extends Node
class_name Log

static func p(tag:String, args:Array=[]):
	print("[", tag, "] ", " ".join(args.map(func(a): return str(a))))
```

Usage:

```gdscript
Log.p("UI", ["populate", names])
```

---

## Data‑driven conventions

* **Resources** for everything gameplay‑visible:

  * `AbilityResource`, `BuffResource`, `StatusResource`, `StatBlockResource`, `EntityResource`.
* **Names as keys** for registries. `.resource_name` is authoritative; no direct node paths.
* **Recursive folder scans** under `res://data/*` on boot. Skip hidden and navigation entries.
* **Tables over branches.** Prefer dictionaries/arrays to map types → effects, rather than long `match` or `if` chains.

---

## UI principles

* **Structured containers** drive everything:

  * **InitiativeBar**: `populate(units:Array)` → creates PortraitButtons from `EntityResource.portrait_path`.
  * **ActionBar**: watches `turn_started(actor)` → reads `actor.$AbilityContainer.get_all()` and spawns buttons with icons and tooltips.
  * **EntityPanel**: `bind(entity)` → subscribes to `hp_changed`, `died`.
  * **CombatLog**: subscribes to `EventBus.event` and appends formatted lines.
* **Zero hard‑wired asset paths in code** (except safe fallbacks like `missing_asset.png`). Icons/portraits come from resources.
* **Public API only** on UI nodes: `populate`, `clear`, `bind`, `show_turn`, `update_hp`.

---

## Architecture

* **Singletons (autoloads):** Registries (`AbilityReg`, `BuffReg`, `StatusReg`), `EventBus`, optional `DamageTable`.
* **Managers as nodes:** `BattleManager`, `TurnManager` are scene children, not autoloads.
* **Signals over lookups:** Prefer connecting to events rather than calling across systems.
* **IDs when needed:** Use `get_instance_id()` and resolve via `instance_from_id()` at use time (IDs are session‑scoped).

---

## Testing habits

* Every feature has a `test_*.gd` beside it in `scenes/tests/**`.
* **Public API only**, no peeking at private members.
* **Leak hygiene:** `autoqfree`, `add_child_autoqfree`, and `assert_no_new_orphans()` in each test file.
* **Integration smoke tests** for vertical slices (e.g., 3 rounds in `TestHost`).

---

## Code style quick list

* **File endings:** `#EOF` comment.
* **Function size:** aim ≤ 40 lines; split after a hop if it grows.
* **Return early** (guard clauses) instead of deep nesting.
* **Typing:**

  * Use explicit types in resources/structs for editor clarity.
  * For registry/query functions that return heterogeneous arrays, prefer **untyped `Array`** to avoid churn.
* **Error handling:**

  * `assert(...)` for programmer errors in tests/dev.
  * `push_warning()` for recoverable data issues (e.g., missing resource).
  * `push_error()` only for critical failures that block progress.

---

## Asset defaults

* Temporary visuals use `res://assets/missing_asset.png`.
* Detective placeholder sprites:

  * `res://assets/characters/detective/detective_side_64.png`
  * `res://assets/characters/detective/detective_snub_64.png`
* Replace by editing `EntityResource.sprite_path` / `portrait_path`.

---

## VS Code & tasks

* **One‑key tests:** tasks for `GUT: all` and fast UI slices.
* **`godot4` on PATH:** symlink in `~/.local/bin` → current Desktop build.
* Restart VS Code after PATH changes.

---

## Commit messages

* Format: `feat(ui): initiative bar populates from turn order`
  Other types: `fix`, `test`, `refactor`, `perf`, `chore`.

---

*This document captures preferences; defer to “Close‑to‑Shore Coding” for the process.*
