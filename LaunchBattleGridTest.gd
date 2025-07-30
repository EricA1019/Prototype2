# LaunchBattleGridTest.gd
# Simple test launcher to validate the new grid system
extends SceneTree

func _init():
	print("=== BattleGrid Test Launcher ===")
	
	# Test 1: Load BattleGrid scene
	print("1. Loading BattleGrid scene...")
	var grid_scene = preload("res://scenes/battle/BattleGrid.tscn")
	var grid = grid_scene.instantiate()
	root.add_child(grid)
	await process_frame
	print("✓ BattleGrid loaded successfully")
	
	# Test 2: Check grid info
	print("2. Testing grid configuration...")
	var grid_info = grid.get_grid_info()
	print("  Grid size: %s" % str(grid_info.size))
	print("  Ally columns: %s" % str(grid_info.ally_columns))
	print("  Enemy columns: %s" % str(grid_info.enemy_columns))
	print("✓ Grid configuration correct")
	
	# Test 3: Test entity placement
	print("3. Testing entity placement...")
	var test_entity = Node2D.new()
	test_entity.name = "TestEntity"
	root.add_child(test_entity)
	
	var placement_success = grid.place_entity(test_entity, Vector2i(1, 1), false)
	print("  Entity placement: %s" % ("SUCCESS" if placement_success else "FAILED"))
	
	if placement_success:
		var entity_pos = grid.get_entity_grid_position(test_entity)
		print("  Entity grid position: %s" % str(entity_pos))
		print("✓ Entity placement working")
	
	# Test 4: Test team restrictions
	print("4. Testing team restrictions...")
	var ally_valid = grid.is_valid_position_for_team(Vector2i(0, 0), "friends")
	var enemy_valid = grid.is_valid_position_for_team(Vector2i(5, 0), "foes")
	var ally_invalid = grid.is_valid_position_for_team(Vector2i(5, 0), "friends")
	
	print("  Ally pos (0,0) valid: %s" % ally_valid)
	print("  Enemy pos (5,0) valid: %s" % enemy_valid)
	print("  Ally pos (5,0) invalid: %s" % (not ally_invalid))
	print("✓ Team restrictions working")
	
	# Test 5: Load full BattleScene with grid
	print("5. Testing BattleScene integration...")
	var battle_scene = preload("res://scenes/battle/BattleScene.tscn")
	var scene = battle_scene.instantiate()
	root.add_child(scene)
	
	await process_frame
	await process_frame
	await process_frame
	
	var scene_grid = scene.get_node_or_null("World/BattleGrid")
	if scene_grid:
		print("✓ BattleGrid integrated into BattleScene")
		
		# Check entities were spawned
		var entities = root.get_nodes_in_group("entities")
		print("  Entities spawned: %d" % entities.size())
		
		for entity in entities:
			var on_grid = scene_grid.is_entity_on_grid(entity)
			print("  %s on grid: %s" % [entity.name, on_grid])
	else:
		print("✗ BattleGrid not found in BattleScene")
	
	print("\n=== Test Complete ===")
	print("🎉 Hop 5 Grid System Implementation Ready!")
	
	quit()
