# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AbilityResource.gd                                                      ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Custom Resource that stores ALL editor‑visible data for a combat skill  ║
# ║ (name, damage‑type, tags, icon, cooldown, etc.).  Loaded at runtime by  ║
# ║ AbilityRegistry.                                                        ║
# ║                                                                        ║
# ║ Author  : Eric Acosta                                                  ║
# ║ Updated : 2025‑07‑25                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝
@tool
@icon("res://assets/textures/icons/icon_ability_resource.png")
extends Resource
class_name AbilityResource


# ─── Exported fields (visible in Inspector) ───────────────────────────────
@export var display_name : String            = "New Ability"
@export var damage_type  : String            = "Physical"  # Physical / Infernal / Holy
@export var tags         : Array[String]     = []          # e.g. [ "DOT", "Ranged" ]
@export var description  : String            = ""
@export var icon_path    : String            = ""          # 64×64 PNG for HUD
@export var cooldown     : int               = 0           # turns between use
@export var buff_to_apply: String            = ""          # e.g. "Poison"

# ─── Convenience helpers ──────────────────────────────────────────────────
func has_tag(t : String) -> bool:
	return t in tags

func _to_string() -> String:
	return "[%s | %s]" % [display_name, damage_type]

#EOF
