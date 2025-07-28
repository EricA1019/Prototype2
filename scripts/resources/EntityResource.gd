@tool
@icon("res://assets/textures/icons/icon_entity.png")
extends Resource
class_name EntityResource

@export var display_name: String = "New Entity"
@export var team: String = "friends"

# Visual assets
@export var portrait_path: String = "res://assets/missing_asset.png"
@export var portrait_texture: Texture2D
@export var sprite_path: String = "res://assets/missing_asset.png"

# Combat data
@export var stat_block: StatBlockResource
@export var defense_type: String = "Physical"
@export var resistances: Dictionary = {"Physical":1.0, "Infernal":1.0, "Holy":1.0}

# Loadout & starts
@export var abilities: Array = []
@export var starting_buffs: Array = []
@export var starting_statuses: Array = []

# AI profile
@export var ai_profile: String = "basic_dps"

func _to_string() -> String:
	return "[%s | %s]" % [display_name, team]
