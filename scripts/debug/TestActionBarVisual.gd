# scripts/debug/TestActionBarVisual.gd
extends Node

# Visual test for ActionBar functionality
func _ready():
	print("ActionBar visual test starting...")
	
	# Load the BattleScene to test ActionBar
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	get_tree().root.add_child(battle_scene)
	
	# Let the scene initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var bm = battle_scene.get_node("BattleManager")
	
	print("ActionBar found: ", action_bar != null)
	print("ActionBar visible: ", action_bar.visible if action_bar else "N/A")
	
	# Get the spawned entity
	var entities = get_tree().get_nodes_in_group("entities")
	if entities.size() > 0:
		var entity = entities[0]
		print("Found entity: ", entity.name)
		print("Entity abilities: ", entity.get_abilities())
		
		# Manually trigger turn to show ActionBar
		print("Triggering turn_started signal...")
		bm.emit_signal("turn_started", entity)
		await get_tree().process_frame
		
		print("ActionBar visible after turn_started: ", action_bar.visible)
		print("ActionBar ability count: ", action_bar.get_ability_count())
		
		# Test manual ability usage
		print("Testing manual ability usage...")
		bm.use_ability(entity, "Shield")
		await get_tree().process_frame
		
		print("Test complete - check ActionBar at bottom of screen!")
		print("You should see Shield and Regen buttons when the entity's turn starts.")
	else:
		print("No entities found!")
	
	print("Visual test setup complete.")
