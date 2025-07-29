# scripts/debug/TestCombatLogVisual.gd
extends Node

# Simple visual test for CombatLog functionality
func _ready():
	print("Manual CombatLog test starting...")
	
	# Test via the actual BattleScene
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	get_tree().root.add_child(battle_scene)
	
	# Let the scene initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	var bm = battle_scene.get_node("BattleManager")
	
	print("CombatLog found: ", combat_log != null)
	print("Initial line count: ", combat_log.get_line_count())
	
	# Test manual damage to see if it gets logged
	var entities = get_tree().get_nodes_in_group("Entity")
	if entities.size() > 0:
		var entity = entities[0]
		print("Found entity: ", entity.name)
		print("Entity HP before damage: ", entity.hp)
		
		# Apply damage and check if it shows up in log
		bm.damage(entity, 10, "Test")
		await get_tree().process_frame
		
		print("Entity HP after damage: ", entity.hp)
		print("Combat log lines after damage: ", combat_log.get_line_count())
		print("Combat log content:\n", combat_log.get_text())
	
	print("Manual test complete - check the combat log panel on the right side of screen!")
	print("You should see timestamped entries including damage and battle events.")
