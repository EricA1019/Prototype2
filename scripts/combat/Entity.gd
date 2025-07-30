@icon("res://assets/textures/icons/icon_entity.png")
extends Node
class_name Entity

# Preload EntityResource type for export and data properties
const EntityResourceType = preload("res://scripts/resources/EntityResource.gd")


signal hp_changed(current: int, max: int)
signal died()

@export var data: EntityResourceType  # assign via Inspector or code
@onready var ability_container = $AbilityContainer  # holds abilities

var hp: int = 0
var speed: int = 0

func _ready() -> void:
	# Add to entities group for console testing
	add_to_group("entities")
	
	if data == null:
		return
	# Safely retrieve stat_block via dynamic property access
	var sb = data.get("stat_block")
	if sb:
		hp = sb.hp_max
		speed = sb.speed
	else:
		hp = 1
		speed = 0

	# Configure visuals if a Sprite2D exists
	var spr: Sprite2D = get_node_or_null("Sprite2D")
	if spr and data.sprite_path != "":
		var tex: Texture2D = load(data.sprite_path)
		if tex:
			spr.texture = tex

	# Push abilities into the container (names only; container resolves)
	if ability_container:
		ability_container.ability_names = data.abilities
		ability_container.resolve()

	# Apply starting buffs/statuses
	var breg := get_node_or_null("/root/BuffReg")
	if breg:
		for b in data.starting_buffs:
			breg.apply_buff(self, b)
	var sreg := get_node_or_null("/root/StatusReg")
	if sreg:
		for s in data.starting_statuses:
			sreg.apply_status(self, s)

func take_turn(bm) -> void:
	# Minimal placeholder AI: basic physical hit on first enemy
	var enemies: Array = bm.get_enemies(self)
	if enemies.is_empty():
		return
	var target = enemies[0]
	# Retrieve stat block resource dynamically
	var sb = data.get("stat_block")
	var atk: int = sb.attack if sb else 1
	var defv: int = int(target.defense) if "defense" in target else 0
	var raw: int = max(0, atk - defv)
	var mult: float = data.resistances.get(data.defense_type, 1.0)
	var amount: int = int(round(max(1.0, raw * mult)))
	# Pass self as attacker so CombatLog shows actor name
	bm.damage(self, target, amount, "Physical")

func apply_damage(amount: int) -> void:
	# Retrieve stat block resource dynamically
	if data == null:
		hp = max(0, hp - amount)
		emit_signal("hp_changed", hp, 30)  # Use default max HP
		if hp == 0:
			emit_signal("died")
		return
	
	var sb = data.get("stat_block")
	var maxhp: int = sb.hp_max if sb else hp
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, maxhp)
	if hp == 0:
		emit_signal("died")

func apply_heal(amount: int) -> void:
	# Retrieve stat block resource dynamically
	if data == null:
		hp = min(30, hp + amount)  # Use default max HP
		emit_signal("hp_changed", hp, 30)
		return
	
	var sb = data.get("stat_block")
	var maxhp: int = sb.hp_max if sb else hp
	hp = min(maxhp, hp + amount)
	emit_signal("hp_changed", hp, maxhp)

func is_dead() -> bool:
	return hp <= 0

func get_team() -> String:
	return data.team if data else "friends"

func get_abilities() -> Array:
	"""Get the list of ability names for this entity"""
	if data and data.abilities:
		return data.abilities
	return []

# Expose defense for quick math in tests
var defense: int:
	get:
		var sb = data.get("stat_block")
		return sb.defense if sb else 0
#EOF
