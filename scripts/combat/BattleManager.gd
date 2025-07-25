# ────────────────────────────────────────────────────────────────────
# BattleManager.gd — Drives rounds & turns for side‑view combat
# ------------------------------------------------------------------
extends Node
class_name BattleManager

var round: int = 0
var initiative_queue: Array = []  # sorted Array[Unit]

## Starts a battle (friends & foes are Arrays of Units)
func start_battle(friends: Array, foes: Array) -> void:
    print("[CombatMgr] Starting battle …")
    round = 1
    _rebuild_queue(friends + foes)
    _run_round()

func _rebuild_queue(units: Array) -> void:
    initiative_queue = units.duplicate()
    initiative_queue.sort_custom(func(a, b): return a.speed > b.speed)
    print("[CombatMgr] Initiative order:", initiative_queue)

func _run_round() -> void:
    print("[CombatMgr] === ROUND %d START ===" % round)
    for unit in initiative_queue:
        # TODO: unit.take_turn()
        pass
    print("[CombatMgr] === ROUND %d END ===" % round)
#EOF
