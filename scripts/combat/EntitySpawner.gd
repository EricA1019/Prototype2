# scripts/combat/EntitySpawner.gd
extends Node
class_name EntitySpawner

@export var entity_resource_path: String = ""
# Position to spawn at
@export var spawn_position: Vector2 = Vector2(0, 0)

# Preload entity scenes
const EntityBase = preload("res://scenes/entities/EntityBase.tscn")
const Detective = preload("res://scenes/entities/Detective.tscn")
const Imp = preload("res://scenes/entities/Imp.tscn")

func spawn() -> Node:
	"""Spawn the default EntityBase (Detective)"""
	return spawn_detective()

func spawn_detective() -> Node:
	print("[Spawner] Spawning Detective")
	var detective: Node = Detective.instantiate()
	_setup_entity(detective)
	return detective

func spawn_imp() -> Node:
	print("[Spawner] Spawning Imp")
	var imp: Node = Imp.instantiate()
	_setup_entity(imp)
	return imp

func spawn_entity_base() -> Node:
	"""Legacy method for spawning EntityBase"""
	print("[Spawner] Spawning EntityBase")
	var ent: Node = EntityBase.instantiate()
	_setup_entity(ent)
	return ent

func _setup_entity(entity: Node) -> void:
	"""Common setup for all spawned entities"""
	# Position on spawn
	if entity is Node2D:
		(entity as Node2D).position = spawn_position
	get_parent().add_child(entity)
	# Trigger ready for headless
	if entity.has_method("_ready"):
		entity._ready()

#EOF
