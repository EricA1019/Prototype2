#!/usr/bin/env python3
# create_combat_managers.py
# Creates node-based TurnManager/BattleManager, EventBus, DamageTable,
# TestHost scene, and an integration GUT test.
#
# Run from your project root (folder containing project.godot):
#   python3 create_combat_managers.py
#
# Re-running is safe: existing files are skipped.

from pathlib import Path
import textwrap

ROOT = Path(__file__).parent.resolve()

FILES: dict[str, str] = {}

def add(path: str, content: str):
    FILES[path] = textwrap.dedent(content).lstrip()

# ───────────────────────────────────────── scripts/combat/TurnManager.gd
add("scripts/combat/TurnManager.gd", r"""
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ TurnManager.gd                                                          ║
# ║ Single-round initiative manager. Sorts by `speed`, yields alive actors, ║
# ║ and skips blocked units (via StatusReg.blocks_turn).                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends Node
class_name TurnManager

signal turn_started(actor: Node)
signal turn_ended(actor: Node)
signal round_completed()

var _queue: Array = []
var _index: int = 0

func build_initiative(units: Array) -> void:
	# Keep only living units, sort by speed desc; tie-break by instance id asc.
	_queue = units.filter(func(u): return _is_alive(u)).duplicate()
	_queue.sort_custom(func(a, b):
		var sa := ("speed" in a) ? a.speed : 0
		var sb := ("speed" in b) ? b.speed : 0
		return (sa == sb) ? (a.get_instance_id() < b.get_instance_id()) : (sa > sb)
	)
	_index = 0

func next_turn() -> Node:
	while _index < _queue.size():
		var actor: Node = _queue[_index]
		if not _is_alive(actor) or _is_blocked(actor):
			_index += 1
			continue
		emit_signal("turn_started", actor)
		return actor
	emit_signal("round_completed")
	return null

func end_turn(actor: Node) -> void:
	emit_signal("turn_ended", actor)
	_index += 1
	if _index >= _queue.size():
		emit_signal("round_completed")

# ─── Helpers ───────────────────────────────────────────────────────────────
func _is_alive(u: Node) -> bool:
	if u == null:
		return false
	if "hp" in u:
		return int(u.hp) > 0
	return true

func _is_blocked(u: Node) -> bool:
	var sr := get_node_or_null("/root/StatusReg")
	return sr != null and sr.blocks_turn(u)
#EOF
""")

# ───────────────────────────────────────── scripts/combat/BattleManager.gd
add("scripts/combat/BattleManager.gd", r"""
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BattleManager.gd                                                        ║
# ║ Orchestrates battle flow. Owns a TurnManager child, advances rounds,    ║
# ║ calls BuffReg/StatusReg round-end ticks, and checks victory.            ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends Node
class_name BattleManager

signal round_started(round: int)
signal round_ended(round: int)
signal battle_ended(result: String)

@onready var tm: TurnManager = $TurnManager

var round: int = 0
var friends: Array = []
var foes: Array = []

func start_battle(p_friends: Array, p_foes: Array) -> void:
	friends = p_friends.duplicate()
	foes    = p_foes.duplicate()
	round = 1
	_emit_round_start()
	_rebuild_and_begin_round()

func end_battle(result: String) -> void:
	emit_signal("battle_ended", result)

# ─── Round Flow ────────────────────────────────────────────────────────────
func _rebuild_and_begin_round() -> void:
	var alive := _living(friends) + _living(foes)
	tm.build_initiative(alive)
	_process_turns()

func _process_turns() -> void:
	var actor := tm.next_turn()
	while actor != null:
		if actor.has_method("take_turn"):
			actor.take_turn(self)
		tm.end_turn(actor)
		if _check_victory():
			return
		actor = tm.next_turn()
	# Round completed
	_emit_round_end()
	_do_round_ticks()
	if _check_victory():
		return
	round += 1
	_emit_round_start()
	_rebuild_and_begin_round()

func _do_round_ticks() -> void:
	var br := get_node_or_null("/root/BuffReg")
	if br:
		br.on_round_end()
	var sr := get_node_or_null("/root/StatusReg")
	if sr:
		sr.on_round_end()

# ─── Queries / Helpers ─────────────────────────────────────────────────────
func get_enemies(of_unit: Node) -> Array:
	return foes if of_unit in friends else friends

func damage(target: Node, amount: int, dmg_type: String = "Physical") -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(amount)
	else:
		if "hp" in target:
			target.hp = max(0, int(target.hp) - amount)
	_event_bus_emit("damage_dealt", {"target": target, "amount": amount, "type": dmg_type})

func heal(target: Node, amount: int) -> void:
	if target.has_method("apply_heal"):
		target.apply_heal(amount)
	else:
		if "hp" in target:
			target.hp = int(target.hp) + amount
	_event_bus_emit("healed", {"target": target, "amount": amount})

func _check_victory() -> bool:
	friends = _living(friends)
	foes    = _living(foes)
	if friends.is_empty():
		end_battle("defeat")
		return true
	if foes.is_empty():
		end_battle("victory")
		return true
	return false

func _living(list: Array) -> Array:
	return list.filter(func(u): return u != null and ("hp" in u and u.hp > 0))

func _emit_round_start() -> void:
	emit_signal("round_started", round)
	_event_bus_emit("round_started", {"round": round})
	print("[CombatMgr] === ROUND ", round, " START ===")

func _emit_round_end() -> void:
	emit_signal("round_ended", round)
	_event_bus_emit("round_ended", {"round": round})
	print("[CombatMgr] === ROUND ", round, " END ===")

# ─── EventBus --------------------------------------------------------------
func _event_bus_emit(kind: String, payload: Dictionary) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.emit_signal("event", kind, payload)
#EOF
""")

# ───────────────────────────────────────── scripts/systems/EventBus.gd
add("scripts/systems/EventBus.gd", r"""
# EventBus.gd — tiny signal-only singleton to decouple systems.
extends Node
class_name EventBus
signal event(kind: String, payload: Dictionary)
#EOF
""")

# ───────────────────────────────────────── scripts/data/DamageTable.gd
add("scripts/data/DamageTable.gd", r"""
# DamageTable.gd — simple type-vs-type modifier lookup (data-driven).
extends Node
class_name DamageTable

var table: Dictionary = {
	"Physical": {"Physical": 1.0, "Infernal": 1.0,  "Holy": 1.0},
	"Infernal": {"Physical": 1.0, "Infernal": 1.0,  "Holy": 0.75},
	"Holy":     {"Physical": 1.0, "Infernal": 1.25, "Holy": 1.0},
}

func modifier(attack_type: String, defense_type: String) -> float:
	return float(table.get(attack_type, {}).get(defense_type, 1.0))
#EOF
""")

# ───────────────────────────────────────── scenes/tests/TestHost.tscn
add("scenes/tests/TestHost.tscn", r"""
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/combat/BattleManager.gd" id="1"]
[ext_resource type="Script" path="res://scripts/combat/TurnManager.gd" id="2"]

[node name="TestHost" type="Node"]

[node name="BattleManager" type="Node" parent="."]
script = ExtResource("1")

[node name="TurnManager" type="Node" parent="BattleManager"]
script = ExtResource("2")
""")

# ───────────────────────────────────────── scenes/tests/test_BattleFlow.gd
add("scenes/tests/test_BattleFlow.gd", r"""
extends "res://addons/gut/test.gd"

const BattleManager = preload("res://scripts/combat/BattleManager.gd")
const TurnManager   = preload("res://scripts/combat/TurnManager.gd")

class MiniUnit:
	extends Node
	var team: String = ""
	var hp: int = 20
	var speed: int = 10
	var dmg_per_turn: int = 5
	func is_dead() -> bool: return hp <= 0
	func apply_damage(a: int) -> void: hp = max(0, hp - a)
	func apply_heal(a: int)   -> void: hp += a
	func take_turn(bm: BattleManager) -> void:
		var enemies := bm.get_enemies(self)
		if enemies.is_empty(): return
		var target: MiniUnit = enemies[0]
		bm.damage(target, dmg_per_turn, "Physical")

func _make_battle() -> BattleManager:
	var bm: BattleManager = add_child_autoqfree(BattleManager.new())
	var tm: TurnManager   = TurnManager.new()
	bm.add_child(tm)
	bm.tm = tm
	return bm

func _unit(team: String, hp: int, speed: int, dpt: int) -> MiniUnit:
	var u: MiniUnit = MiniUnit.new()
	add_child_autoqfree(u)
	u.team = team; u.hp = hp; u.speed = speed; u.dmg_per_turn = dpt
	return u

func test_three_round_flow_and_ticks() -> void:
	var bm = _make_battle()
	var f1 = _unit("friends", 30, 12, 6)
	var f2 = _unit("friends", 24, 10, 5)
	var e1 = _unit("foes",    26, 11, 4)
	var e2 = _unit("foes",    22,  8, 3)

	bm.start_battle([f1, f2], [e1, e2])

	assert_true(bm.round >= 3)
	assert_true(e1.hp < 26)
	assert_true(e2.hp < 22)

func test_skip_blocked_turns() -> void:
	var bm = _make_battle()
	var f = _unit("friends", 20, 10, 5)
	var e = _unit("foes",    20, 10, 5)

	# Apply Stunned so enemy's first turn is skipped
	var sr = get_node_or_null("/root/StatusReg")
	if sr:
		sr.apply_status(e, "Stunned", 1)

	bm.start_battle([f], [e])
	assert_true(e.hp < 20)
	assert_true(e.hp > 0)

func test_victory_condition() -> void:
	var bm = _make_battle()
	var f = _unit("friends", 40, 20, 20)
	var e = _unit("foes",    10,  1,  1)

	var ended := false
	bm.battle_ended.connect(func(result): ended = true)

	bm.start_battle([f], [e])
	assert_true(ended)

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
""")

# ───────────────────────────────────────── writer

DIRS = [
    "scripts/combat",
    "scripts/systems",
    "scripts/data",
    "scenes/tests",
]

def main():
    for d in DIRS:
        (ROOT / d).mkdir(parents=True, exist_ok=True)
        print(f"[dir] {d}")
    for rel, text in FILES.items():
        path = ROOT / rel
        if path.exists():
            print(f"[skip] {rel} (exists)")
            continue
        path.write_text(text)
        print(f"[write] {rel}")
    print("\nDone. Now add EventBus (and your registries) to Project → AutoLoad.")
    print('Run integration test: godot4 --headless -s addons/gut/cli/gut_cmdln.gd '
          '--path . -gdir=res://scenes/tests -ginclude_subdirs -gexit -glog=2')

if __name__ == "__main__":
    main()
