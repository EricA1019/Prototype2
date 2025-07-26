# scripts/combat/EntitySpawner.gd
extends Node
class_name EntitySpawner

@export var entity_resource_path: String = ""
# Position to spawn at
@export var spawn_position: Vector2 = Vector2(0, 0)

# Preload main entity scene
const EntityScene = preload("res://scenes/entities/EntityBase.tscn")

func spawn() -> Node:
	print("[Spawner] spawn base EntityScene")
	var ent: Node = EntityScene.instantiate()
	# Position on spawn
	if ent is Node2D:
		(ent as Node2D).position = spawn_position
	get_parent().add_child(ent)
	# Trigger ready for headless
	if ent.has_method("_ready"):
		ent._ready()
	return ent

#EOF
