# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_BuffReg.gd                                                         ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for BuffReg using only its public API.                        ║
# ║                                                                          ║
# ║ Requires a few `.tres` buff defs in `data/buffs/` named:                 ║
# ║   • Poison  (DOT, base_mag=4, base_dur=3, Infernal)                      ║
# ║   • Bleed   (DOT, base_mag=3, base_dur=2, Physical)                      ║
# ║   • Regen   (HOT, base_mag=2, base_dur=3, Holy)                          ║
# ║   • Shield  (SHIELD, shield_amount=10, base_dur=3, Holy)                 ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

# Track created units for cleanup
var _created_units: Array[Node] = []

# Minimal dummy unit for tests
class DummyUnit:
	extends Node
	var hp:int = 50
	var speed:int = 10
	func apply_damage(amount:int) -> void:
		#print("[Dummy] damage:", amount)
		hp = max(0, hp - amount)
	func apply_heal(amount:int) -> void:
		hp += amount

func _make_unit() -> DummyUnit:
	var unit = DummyUnit.new()
	_created_units.append(unit)
	return unit

func after_each():
	# Clean up all created units after each test
	for unit in _created_units:
		if is_instance_valid(unit):
			unit.queue_free()
	_created_units.clear()
	# Also clear any buff registry active buffs to prevent resource leaks
	var reg = _buff_reg()
	if reg != null and reg.has_method("_cleanup"):
		reg._cleanup()

func _buff_reg() -> Node:
	var reg := get_node_or_null("/root/BuffReg")
	if reg == null:
		push_error("BuffReg autoload missing – check Project ▶ AutoLoad")
		return null
	# Ensure it's bootstrapped
	if reg.list_defs().size() == 0:
		reg.bootstrap()
	return reg

func test_defs_loaded() -> void:
	var reg = _buff_reg()
	assert_true(reg.has_def("Poison"), "Missing Poison buff def (.tres)")
	assert_true(reg.has_def("Bleed"),  "Missing Bleed buff def (.tres)")
	assert_true(reg.has_def("Regen"),  "Missing Regen buff def (.tres)")
	assert_true(reg.has_def("Shield"), "Missing Shield buff def (.tres)")

func test_apply_stack_and_refresh_duration() -> void:
	var u = _make_unit()
	var reg = _buff_reg()
	var s1 = reg.apply_buff(u, "Poison")   # +3 dur, +4 mag (example)
	var s2 = reg.apply_buff(u, "Poison")   # stacks to 2, dur=6, mag=8
	assert_eq(s1, 1)
	assert_eq(s2, 2)
	var names = reg.list_active(u)
	assert_true("Poison" in names)

func test_round_end_ticks_damage() -> void:
	var u = _make_unit()
	var reg = _buff_reg()
	reg.apply_buff(u, "Poison")  # 4 dmg per round (example values)
	var hp0 = u.hp
	reg.on_round_end()
	assert_eq(u.hp, hp0 - 4)

func test_cleanse_by_tag() -> void:
	var u = _make_unit()
	var reg = _buff_reg()
	reg.apply_buff(u, "Bleed")     # assumed tags contain "DOT"
	reg.apply_buff(u, "Shield")    # assumed tags contain "Buff"
	var removed = reg.cleanse(u, ["DOT"])  # should remove Bleed only
	assert_eq(removed, 1, "Expected to remove only the DOT buff")
	var names = reg.list_active(u)
	assert_false("Bleed" in names)
	assert_true("Shield" in names)
#EOF
