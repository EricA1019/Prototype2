@icon("res://assets/textures/icons/icon_ability_container.png")# Holds an entity's abilities, resolved from names via AbilityReg.
extends Node
class_name AbilityCont

signal abilities_resolved(names: Array)

@export var ability_names: Array = []
var _abilities: Array = []   # Array[AbilityResource]

func _ready() -> void:
	resolve()

func resolve() -> void:
	_abilities.clear()
	var reg := get_node_or_null("/root/AbilityReg")
	if reg:
		for n in ability_names:
			# Determine ability key from String or Resource
			var key: String
			if typeof(n) == TYPE_STRING:
				key = n
			elif n is Resource:
				# Use resource_name or fallback to file basename
				if n.resource_name != "":
					key = n.resource_name
				else:
					key = n.resource_path.get_file().get_basename()
			else:
				push_warning("[AbilityContainer] Unsupported ability identifier: %s" % str(n))
				continue
			# Resolve via registry
			var a = reg.get_ability(key)
			if a:
				_abilities.append(a)
	emit_signal("abilities_resolved", list_names())

func list_names() -> Array:
	return ability_names.duplicate()

func get_all() -> Array:
	return _abilities.duplicate()
#EOF
