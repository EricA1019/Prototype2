# LaunchBattleSceneTest.gd
extends SceneTree

func _init():
	print("=== Direct BattleScene Test ===")
	
	# Load registries first
	var ability_reg = preload("res://scripts/registries/AbilityReg.gd").new()
	ability_reg.name = "AbilityReg" 
	root.add_child(ability_reg)
	
	var buff_reg = preload("res://scripts/registries/BuffReg.gd").new()
	buff_reg.name = "BuffReg"
	root.add_child(buff_reg)
	
	var status_reg = preload("res://scripts/registries/StatusReg.gd").new()
	status_reg.name = "StatusReg"
	root.add_child(status_reg)
	
	# Wait for registries to initialize
	await process_frame
	await process_frame
	
	print("✓ Registries loaded")
	
	# Now try loading BattleScene
	print("Loading BattleScene...")
	
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	root.add_child(battle_scene)
	print("✓ BattleScene added to tree")
	
	# Let it initialize
	await process_frame
	await process_frame
	await process_frame
	
	print("✓ BattleScene initialized")
	
	# Check results
	var entities = root.get_nodes_in_group("entities")
	print("Entities spawned: ", entities.size())
	
	for entity in entities:
		print("  - %s (Team: %s)" % [entity.name, entity.get_team()])
	
	var action_bar = battle_scene.get_node_or_null("CanvasLayer/UI/ActionBar")
	print("ActionBar found: ", action_bar != null)
	if action_bar:
		print("ActionBar visible: ", action_bar.visible)
	
	print("=== Test Complete ===")
	print("BattleScene should be running successfully!")
	
	# Keep running for a bit to see if there are any runtime errors
	await create_timer(2.0).timeout
	print("No crashes detected - Success!")
	
	quit()
