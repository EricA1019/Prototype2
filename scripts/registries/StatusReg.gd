# ────────────────────────────────────────────────────────────────────
# StatusReg.gd — Tracks transient combat statuses (e.g. Stunned)
# ------------------------------------------------------------------
extends Node
class_name StatusRegistry

var _states: Dictionary = {}  # {unit: {status_name: duration}}

func clear() -> void:
    print("[StatusReg] Clearing all runtime states …")
    _states.clear()
#EOF
