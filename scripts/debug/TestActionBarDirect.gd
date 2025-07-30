# scripts/debug/TestActionBarDirect.gd
extends Node

func _ready():
	print("=== ActionBar Direct Test ===")
	
	# Load BattleScene directly
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	get_tree().root.add_child(battle_scene)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ BattleScene loaded")
	
	# Check components
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	var bm = battle_scene.get_node("BattleManager")
	
	print("✓ ActionBar found: ", action_bar != null)
	print("✓ CombatLog found: ", combat_log != null)
	print("✓ BattleManager found: ", bm != null)
	
	if action_bar:
		print("ActionBar visible: ", action_bar.visible)
		print("ActionBar ability count: ", action_bar.get_ability_count())
		
		# Check for entities
		var entities = get_tree().get_nodes_in_group("entities")
		print("Entities found: ", entities.size())
		
		if entities.size() > 0:
			var detective = entities[0]
			print("Detective name: ", detective.name)
			print("Detective abilities: ", detective.get_abilities())
			
			# Force ActionBar to show
			print("Forcing ActionBar to show...")
			action_bar.show_for(detective)
			
			await get_tree().process_frame
			
			print("ActionBar visible after show_for: ", action_bar.visible)
			print("ActionBar ability count after show_for: ", action_bar.get_ability_count())
	
	print("=== Test Complete ===")
	print("Look for the ActionBar at the bottom of the screen!")
	print("The Combat Log title should also be removed.")
