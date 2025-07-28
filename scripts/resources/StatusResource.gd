# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ StatusResource.gd                                                       ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Data Resource describing a *status* (binary or timed).                  ║
# ║ Examples: Stunned, Guarded, Marked, Channeling, Stealthed.              ║
# ║                                                                          ║
# ║ Durations                                                                ║
# ║   • base_duration > 0  → decremented at **round end**.                   ║
# ║   • base_duration == 0 → indefinite until explicitly cleared.            ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
@tool
@icon("res://assets/textures/icons/icon_status_resource.png")
extends Resource
class_name StatusResource
# ─── Exported fields (visible in Inspector) ────────────────────────────────
@export var is_binary   : bool = true     # if true + base_duration==0 → on/off flag, no stacks
@export var display_name : String        = "New Status"
@export var tags         : Array[String] = []          # e.g. ["Control", "Debuff"]

# Behavior flags ------------------------------------------------------------
@export var affects_turn : bool = false   # true → unit loses ability to act this turn (e.g., Stunned)
@export var blocks_actions : bool = false # prevents using abilities (even if turn not fully lost)

# Duration & stacks ---------------------------------------------------------
@export var base_duration : int = 0       # rounds added per application (0 = indefinite)
@export var max_stacks    : int = 1       # <0 = unlimited; if is_binary, this should be 1

# Optional icon for HUD
@export var icon_path     : String = ""

# Immunities granted while active
@export var grants_immunity_tags : Array[String] = []  # e.g. ["DOT", "Control"]

func has_tag(t:String) -> bool:
	return t in tags

func _to_string() -> String:
	var dur := "%dr" % base_duration if base_duration > 0 else "∞"
	return "[%s | dur %s | %s]" % [display_name, dur, ", ".join(tags)]
#EOF
