# scripts/debug/TestNewEntities.gd
extends Node

func _ready():
	print("=== New Entities Test ===")
	
	# Load BattleScene with new entities
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	get_tree().root.add_child(battle_scene)
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ BattleScene loaded with new entities")
	
	# Check entities
	var entities = get_tree().get_nodes_in_group("entities")
	print("Entities found: ", entities.size())
	
	for entity in entities:
		print("Entity: %s (Team: %s)" % [entity.name, entity.get_team()])
		print("  Abilities: %s" % str(entity.get_abilities()))
		print("  HP: %d" % entity.hp)
	
	# Check ActionBar
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var bm = battle_scene.get_node("BattleManager")
	
	if entities.size() >= 2:
		var detective = null
		var imp = null
		
		for entity in entities:
			if entity.name == "Detective":
				detective = entity
			elif entity.name == "Imp":
				imp = entity
		
		if detective:
			print("\n=== Testing Detective ActionBar ===")
			bm.emit_signal("turn_started", detective)
			await get_tree().process_frame
			
			print("ActionBar visible: ", action_bar.visible)
			print("ActionBar ability count: ", action_bar.get_ability_count())
			
			var buttons = action_bar.button_container.get_children()
			var button_names = []
			for button in buttons:
				button_names.append(button.text)
			print("Button names: ", button_names)
		
		if imp:
			print("\n=== Testing Imp ActionBar ===")
			bm.emit_signal("turn_ended", detective)
			bm.emit_signal("turn_started", imp)
			await get_tree().process_frame
			
			print("ActionBar visible: ", action_bar.visible)
			print("ActionBar ability count: ", action_bar.get_ability_count())
			
			var buttons = action_bar.button_container.get_children()
			var button_names = []
			for button in buttons:
				button_names.append(button.text)
			print("Button names: ", button_names)
	
	print("\n=== Test Complete ===")
	print("Detective vs Imp battle setup!")
	print("Check the screen for:")
	print("- Detective (friends team) with Shield, Regen buttons")
	print("- Imp (foes team) with Attack, Poison, Bleed buttons")
	print("- ActionBar switching between entities")
