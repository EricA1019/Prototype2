# DamageTable.gd — simple type-vs-type modifier lookup (data-driven).
extends Node
class_name DamageTable

var table: Dictionary = {
	"Physical": {"Physical": 1.0, "Infernal": 1.0,  "Holy": 1.0},
	"Infernal": {"Physical": 1.0, "Infernal": 1.0,  "Holy": 0.75},
	"Holy":     {"Physical": 1.0, "Infernal": 1.25, "Holy": 1.0},
}

func modifier(attack_type: String, defense_type: String) -> float:
	return float(table.get(attack_type, {}).get(defense_type, 1.0))
#EOF
