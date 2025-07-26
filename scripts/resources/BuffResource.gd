# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BuffResource.gd                                                         ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Data‑only Resource that describes a buff/debuff. Used by BuffReg.       ║
# ║                                                                          ║
# ║ • DOT: damage each round (hp -= base_magnitude per stack)                ║
# ║ • HOT: healing each round (hp += base_magnitude per stack)               ║
# ║ • SHIELD: absorbs incoming damage (no per‑round tick)                    ║
# ║                                                                          ║
# ║ Stacking model (default):                                                ║
# ║   – applying again **adds a stack** (if max_stacks < 0 → unlimited)      ║\
# ║   – total magnitude **adds**                                            ║\
# ║   – duration **extends** by base_duration (not clamped)                  ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
@tool
#@icon("res://assets/icons/buff_resource.svg")
extends Resource
class_name BuffResource


# ─── Inspector fields ──────────────────────────────────────────────────────
@export var display_name    : String        = "New Buff"
@export var tags            : Array[String] = []           # e.g. ["DOT", "Poison"]
@export var damage_type     : String        = "Physical"   # For DOT/HOT logs & resist tables

@export var is_dot          : bool          = false
@export var is_hot          : bool          = false
@export var is_shield       : bool          = false

@export var base_magnitude  : int           = 0            # per‑round damage/heal (per stack)
@export var base_duration   : int           = 1            # rounds added per application
@export var max_stacks      : int           = -1           # <0 = unlimited

# Shields: on application, shield_remaining += shield_amount (per stack)
@export var shield_amount   : int           = 0

# Optional portrait/icon for HUD
@export var icon_path       : String        = ""

# ─── Helpers ───────────────────────────────────────────────────────────────
func has_tag(t:String) -> bool:
	return t in tags

func _to_string() -> String:
	var kind := "DOT" if is_dot else "HOT" if is_hot else "SHIELD" if is_shield else "BUFF"
	return "[%s | %s | %s]" % [display_name, kind, damage_type]
#EOF