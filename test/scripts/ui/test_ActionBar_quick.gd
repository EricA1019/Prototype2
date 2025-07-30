# test/scripts/ui/test_ActionBar_quick.gd
extends GutTest

func test_quick_actionbar_functionality():
	"""Quick test to verify basic ActionBar functionality"""
	print("=== Quick ActionBar Test ===")
	
	# Test 1: Scene creation
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	print("✓ ActionBar scene created successfully")
	assert_not_null(action_bar, "ActionBar should instantiate")
	
	# Test 2: Initial state
	assert_false(action_bar.visible, "Should start hidden")
	assert_eq(action_bar.get_ability_count(), 0, "Should start with no abilities")
	print("✓ Initial state correct")
	
	# Test 3: Mock entity interaction
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.set("abilities", ["Shield", "Regen"])
	add_child(mock_entity)
	
	action_bar.show_for(mock_entity)
	await get_tree().process_frame
	
	assert_true(action_bar.visible, "Should be visible after show_for")
	assert_eq(action_bar.get_ability_count(), 2, "Should have 2 buttons")
	print("✓ Show_for functionality works")
	
	# Test 4: Clear functionality
	action_bar.clear()
	assert_false(action_bar.visible, "Should be hidden after clear")
	assert_eq(action_bar.get_ability_count(), 0, "Should have no buttons after clear")
	print("✓ Clear functionality works")
	
	print("=== All ActionBar tests passed! ===")
	
	mock_entity.queue_free()
	action_bar.queue_free()
