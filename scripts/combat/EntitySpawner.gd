# scripts/combat/EntitySpawner.gd
extends Node
class_name EntitySpawner

@export var entity_resource_path: String = ""
# Reference to the battle grid for positioning
var battle_grid: Node = null

# Spawn counters for automatic positioning
var ally_spawn_count: int = 0
var enemy_spawn_count: int = 0

# Preload entity scenes
const EntityBase = preload("res://scenes/entities/EntityBase.tscn")
const Detective = preload("res://scenes/entities/Detective.tscn")
const Imp = preload("res://scenes/entities/Imp.tscn")

func _ready() -> void:
	# Find battle grid in parent nodes
	battle_grid = _find_battle_grid()
	if battle_grid:
		print("[Spawner] Connected to BattleGrid")
	else:
		print("[Spawner] Warning: No BattleGrid found - using legacy positioning")

func _find_battle_grid() -> Node:
	"""Find BattleGrid in the scene tree"""
	var current = get_parent()
	while current:
		var grid = current.find_child("BattleGrid", false, false)
		if grid and grid.get_script() != null:
			var script_path = grid.get_script().get_path()
			if "BattleGrid" in script_path:
				return grid
		current = current.get_parent()
	return null

func spawn() -> Node:
	"""Spawn the default EntityBase (Detective)"""
	return spawn_detective()

func spawn_detective() -> Node:
	print("[Spawner] Spawning Detective")
	var detective: Node = Detective.instantiate()
	_setup_entity(detective, "friends")
	return detective

func spawn_imp() -> Node:
	print("[Spawner] Spawning Imp")
	var imp: Node = Imp.instantiate()
	_setup_entity(imp, "foes")
	return imp

func spawn_entity_base() -> Node:
	"""Legacy method for spawning EntityBase"""
	print("[Spawner] Spawning EntityBase")
	var ent: Node = EntityBase.instantiate()
	_setup_entity(ent, "friends")
	return ent

func spawn_multiple(entity_configs: Array) -> Array[Node]:
	"""Spawn multiple entities with specific configurations
	entity_configs: Array of {type: String, team: String, is_large: bool}"""
	var spawned_entities: Array[Node] = []
	var entity_counters = {}  # Track counts for unique naming
	
	for config in entity_configs:
		var entity: Node = null
		var entity_type = config.get("type", "detective")
		
		match entity_type:
			"detective":
				entity = Detective.instantiate()
			"imp":
				entity = Imp.instantiate()
			"entity_base":
				entity = EntityBase.instantiate()
			_:
				print("[Spawner] Unknown entity type: %s" % entity_type)
				continue
		
		# Give entity a unique name
		if entity_type in entity_counters:
			entity_counters[entity_type] += 1
			entity.name = "%s_%d" % [entity_type.capitalize(), entity_counters[entity_type]]
		else:
			entity_counters[entity_type] = 1
			entity.name = entity_type.capitalize()
		
		var team = config.get("team", "friends")
		var is_large = config.get("is_large", false)
		
		if _setup_entity(entity, team, is_large):
			spawned_entities.append(entity)
		else:
			entity.queue_free()
			print("[Spawner] Failed to spawn entity: %s" % config)
	
	return spawned_entities

func _setup_entity(entity: Node, team: String, is_large: bool = false) -> bool:
	"""Setup and position entity on the battlefield"""
	# Add to tree first
	get_parent().add_child(entity)
	
	# Set team if entity supports it
	if entity.has_method("set_team"):
		entity.set_team(team)
	elif "team" in entity:
		entity.team = team
	
	# Position using grid system if available
	if battle_grid:
		var spawn_index = ally_spawn_count if team.to_lower() in ["friends", "allies"] else enemy_spawn_count
		var grid_pos = battle_grid.get_spawn_position_for_team(team, spawn_index, is_large)
		
		if grid_pos.x >= 0:  # Valid position found
			if battle_grid.place_entity(entity, grid_pos, is_large):
				print("[Spawner] Placed %s at grid position %s" % [entity.name, grid_pos])
				
				# Update spawn counters
				if team.to_lower() in ["friends", "allies"]:
					ally_spawn_count += 1
				else:
					enemy_spawn_count += 1
				
				# Trigger ready for headless
				if entity.has_method("_ready"):
					entity._ready()
				return true
			else:
				print("[Spawner] Failed to place %s on grid" % entity.name)
		else:
			print("[Spawner] No valid grid position for %s (team: %s)" % [entity.name, team])
	
	# Fallback to legacy positioning if grid placement fails
	print("[Spawner] Using legacy positioning for %s" % entity.name)
	if entity is Node2D:
		var fallback_pos = Vector2(100 + ally_spawn_count * 150, 200) if team.to_lower() in ["friends", "allies"] else Vector2(600 + enemy_spawn_count * 150, 200)
		(entity as Node2D).position = fallback_pos
	
	# Update spawn counters
	if team.to_lower() in ["friends", "allies"]:
		ally_spawn_count += 1
	else:
		enemy_spawn_count += 1
	
	# Trigger ready for headless
	if entity.has_method("_ready"):
		entity._ready()
	return true

func reset_spawn_counters() -> void:
	"""Reset spawn counters for new battles"""
	ally_spawn_count = 0
	enemy_spawn_count = 0
	print("[Spawner] Spawn counters reset")

#EOF
