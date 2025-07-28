# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_StatusReg.gd                                                       ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Tests the StatusReg public API. Requires .tres status defs:             ║
# ║   • Stunned  (affects_turn, base_duration=1, tags=["Control"])         ║
# ║   • Guarded  (is_binary, base_duration=2, tags=["Guard"])              ║
# ║   • Marked   (base_duration=3, tags=["Debuff"])                       ║
# ║   • Channeling (base_duration=2, blocks_actions=true, tags=["State"])   ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

class Dummy:
    extends Node
    var hp: int = 40
    var speed: int = 8

func _unit() -> Dummy:
    var u := Dummy.new()
    autoqfree(u)
    return u

func _reg() -> Node:
    var r := get_node("/root/StatusReg")
    if r == null:
        push_error("StatusReg autoload not found")
        return null
    r.bootstrap()
    return r

func test_defs_present() -> void:
    var r = _reg()
    assert_true(r.has_def("Stunned"))
    assert_true(r.has_def("Guarded"))
    assert_true(r.has_def("Marked"))
    assert_true(r.has_def("Channeling"))

func test_apply_and_blocks_turn() -> void:
    var r = _reg()
    var u = _unit()
    r.apply_status(u, "Stunned")
    assert_true(r.blocks_turn(u), "Stunned should block the unit's turn")

func test_extend_duration_and_expire() -> void:
    var r = _reg()
    var u = _unit()
    r.apply_status(u, "Marked", 2)   # 2 rounds
    r.on_round_end()                 # → 1
    assert_true(r.has_status(u, "Marked"))
    r.on_round_end()                 # → 0 expire
    assert_false(r.has_status(u, "Marked"))

func test_clear_by_tags() -> void:
    var r = _reg()
    var u = _unit()
    r.apply_status(u, "Guarded")
    r.apply_status(u, "Marked")
    var removed: int = r.clear_by_tags(u, ["Debuff"])   # should remove Marked only
    assert_eq(removed, 1)
    assert_true(r.has_status(u, "Guarded"))
    assert_false(r.has_status(u, "Marked"))

func test_no_new_orphans() -> void:
    assert_no_new_orphans()

func after_each():
    # Reset or clean up StatusReg between tests if needed.
    var r = get_node_or_null("/root/StatusReg")
    if r and r.has_method("reset_statuses"):
        r.reset_statuses()
#EOF