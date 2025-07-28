Love the snapshot—perfect time to add just‑enough UI. Here’s an ordered set of **short hops** that each give you a clear on‑screen win and minimal/new code. GUT is optional now; I still note a tiny smoke test where it buys stability.

---

## Hop 1 — **Entity Panel (UnitCard)**

Shows the active unit’s **portrait · name · HP bar**.

**Files**

* `scenes/ui/UnitCard.tscn` (VBox → TextureRect, Label, ProgressBar)
* `scripts/ui/UnitCard.gd`
  `bind(entity)`, `update_hp(cur,max)`, `show_turn(entity)`

**Wire**

* Place fixed top‑left in `BattleScene` (`CanvasLayer/UI/UnitCard`).
* Connect `hp_changed`, `died`; listen to `BattleManager.turn_started(actor)`.

**Acceptance (manual)**

* HP bar reflects damage when you call `apply_damage()` from the console.
* Name/portrait match the Detective.
* Logs: `[UI][UnitCard] bind …`, `update_hp …`.

**Optional test**

* `test_UnitCard_smoke.gd`: bind → damage → bar value changed.

---

## Hop 2 — **Combat Log**

Scrollable text list; every major event prints a line.

**Files**

* `scenes/ui/CombatLog.tscn` (Panel → VBox + RichTextLabel inside ScrollContainer)
* `scripts/ui/CombatLog.gd`
  `append(text)`, `clear()`

**Wire**

* Subscribe to `EventBus.event(kind, payload)` or directly to BM signals for now:

  * `round_started`, `turn_started/ended`, `damage_dealt`, `dot_tick`, `status_applied`, `buff_applied`, `battle_ended`.

**Acceptance**

* After 1–2 rounds, the panel shows chronological lines; scroll sticks to bottom.

**Optional test**

* After a scripted mini‑battle, `get_line_count() >= N`.

---

## Hop 3 — **Action Bar (display only + stub click)**

Auto‑populate buttons from `AbilityContainer`; no target selection yet—auto‑target first valid enemy.

**Files**

* `scenes/ui/ActionBar.tscn` (HBox of buttons)
* `scripts/ui/ActionBar.gd`
  `show_for(entity)`, `clear()`

**Wire**

* On `turn_started(actor)`, `show_for(actor)`.
* Button press → `BattleManager.use_ability(actor, ability_name)` (for now, this can call existing DOT/HOT logic or just log).

**Acceptance**

* Detective shows **Regen** and **Shield**.
* Clicking logs `[UI][ActionBar] use Shield on E1` and applies effect if wired.

**Optional test**

* Instantiate bar, pass mock entity with two abilities → two buttons exist.

---

## Hop 4 — **Damage text popups & death fade**

Tiny **Label2D** (or `FloatingText2D.gd`) that rises and fades; entity sprite dims on death (you already fade in InitBar).

**Files**

* `scripts/ui/FloatingText2D.gd`
  `show_amount(world_pos, text)`; self‑`queue_free()` after tween.
* `scenes/ui/FloatingText2D.tscn`

**Wire**

* `BattleManager.damage(target, amt, type)` emits `damage_dealt`; spawn popup at target sprite position.

**Acceptance**

* Dealing damage shows a popup and the sprite fades when HP hits 0.

---

## Hop 5 — **Multi‑spawn (2v2) + victory banner**

Extend spawner to take arrays; simple banner overlay on `battle_ended`.

**Files**

* Update `EntitySpawner.gd` → `spawn_many(res_paths:Array, positions:Array[Vector2])`
* `scenes/ui/VictoryBanner.tscn` + `scripts/ui/VictoryBanner.gd` (`show(text)`)

**Acceptance**

* Two portraits per side in InitBar; when one team drops, banner says **Victory**.

---

## Hop 6 — **Camera basics & debug hotkeys**

* WASD / arrow pan, `+/-` zoom; `F` focus current actor.
* Debug keys: `1` damage active for 5, `2` heal 5, `N` force next turn.

**Acceptance**

* Keys function; log lines confirm actions.

---

### Placement summary

* `CanvasLayer/UI/UnitCard` – top‑left.
* `CanvasLayer/UI/InitiativeBar` – top‑center (already).
* `CanvasLayer/UI/ActionBar` – bottom‑center.
* `CanvasLayer/UI/CombatLog` – right side, fixed width.
* `World` – spawns entities; `FloatingText2D` instances added under `World`.
* `Camera2D` – group **Camera**.

---

### Small public APIs to add

* **BattleManager**

  * `signal damage_dealt(attacker, target, amount, dtype)`
  * `func use_ability(actor, name:String)`: find ability via `AbilityReg`, apply basic effect, emit logs/events.
* **EventBus** (optional now): `emit(kind:String, payload:Dictionary)`.

---

### Want me to scaffold Hop 1 (UnitCard) right away?

I can drop a Python script that writes:

* `UnitCard.gd/tscn`
* `CombatLog.gd/tscn` (if you want to combine Hops 1–2)
* minimal changes to `BattleScene.gd` to bind and position
  …and a tiny smoke test, or skip the test if you prefer purely manual for this slice. Which hop(s) shall I generate?
