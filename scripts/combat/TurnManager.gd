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
        var sa: int = a.speed if ("speed" in a) else 0
        var sb: int = b.speed if ("speed" in b) else 0
        return (a.get_instance_id() < b.get_instance_id()) if (sa == sb) else (sa > sb)
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


# Public snapshot for UI
func get_queue_snapshot() -> Array:
    return _queue.duplicate()
