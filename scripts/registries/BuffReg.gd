# ────────────────────────────────────────────────────────────────────
# BuffReg.gd — Applies, stacks, and expires buffs & debuffs
# ------------------------------------------------------------------
extends Node
class_name BuffRegistry

var _buff_defs: Dictionary = {}  # {buff_name: BuffResource}

func bootstrap() -> void:
    print("[BuffReg] Bootstrapping …")
    _buff_defs.clear()
    # TODO: replicate recursive load as in AbilityReg

# Placeholder API --------------------------------------------------
func apply_buff(target, buff_name: String, duration: int, magnitude: float = 0):
    # TODO: add runtime tracking & stacking logic
    print("[BuffReg] Applying %s to %s (dur=%d, mag=%s)" % [buff_name, target, duration, magnitude])
#EOF
