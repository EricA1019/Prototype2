@tool
extends Resource
class_name StatBlockResource

@export var hp_max: int = 30
@export var speed: int = 10
@export var attack: int = 6
@export var defense: int = 2
# TODO: crit_chance, crit_mult, potency, evasion, block, etc.

func _to_string() -> String:
	return "[HP %d | SPD %d | ATK %d | DEF %d]" % [hp_max, speed, attack, defense]
#EOF
