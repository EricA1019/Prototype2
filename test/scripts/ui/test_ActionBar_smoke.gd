# test/scripts/ui/test_ActionBar_smoke.gd
extends GutTest

func test_action_bar_creation():
	# Test that ActionBar can be instantiated
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	
	assert_not_null(action_bar, "ActionBar should instantiate")
	assert_true(action_bar is Panel, "ActionBar should be a Panel")
	
	# Add to scene tree for proper initialization
	add_child(action_bar)
	await get_tree().process_frame
	
	assert_not_null(action_bar.button_container, "ButtonContainer should be found")
	
	# Should start hidden
	assert_false(action_bar.visible, "ActionBar should start hidden")
	assert_eq(action_bar.get_ability_count(), 0, "Should start with no abilities")
	
	action_bar.queue_free()

func test_action_bar_show_for_entity():
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Create mock entity with abilities
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.set_script(preload("res://test/scripts/helpers/MockEntity.gd"))
	
	# Mock the get_abilities method
	mock_entity.set("abilities", ["Shield", "Regen"])
	
	# Show action bar for entity
	action_bar.show_for(mock_entity)
	
	# Should now be visible with buttons
	assert_true(action_bar.visible, "ActionBar should be visible")
	assert_eq(action_bar.get_ability_count(), 2, "Should have 2 ability buttons")
	assert_eq(action_bar.get_current_entity(), mock_entity, "Should track current entity")
	
	mock_entity.queue_free()
	action_bar.queue_free()

func test_action_bar_clear():
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Create mock entity and show
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.set("abilities", ["Shield"])
	action_bar.show_for(mock_entity)
	
	# Verify setup
	assert_true(action_bar.visible, "Should be visible after show_for")
	assert_eq(action_bar.get_ability_count(), 1, "Should have 1 button")
	
	# Clear and verify
	action_bar.clear()
	assert_false(action_bar.visible, "Should be hidden after clear")
	assert_eq(action_bar.get_ability_count(), 0, "Should have no buttons after clear")
	assert_eq(action_bar.get_current_entity(), null, "Should have no current entity")
	
	mock_entity.queue_free()
	action_bar.queue_free()

func test_action_bar_null_safety():
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Test with null entity - should not crash
	action_bar.show_for(null)
	assert_false(action_bar.visible, "Should remain hidden with null entity")
	assert_eq(action_bar.get_ability_count(), 0, "Should have no buttons with null entity")
	
	action_bar.queue_free()

func test_action_bar_entity_without_abilities():
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Create entity without abilities
	var mock_entity = Node.new()
	mock_entity.name = "NoAbilities"
	
	action_bar.show_for(mock_entity)
	
	# Should be visible but with no buttons
	assert_true(action_bar.visible, "Should be visible even with no abilities")
	assert_eq(action_bar.get_ability_count(), 0, "Should have no buttons for entity without abilities")
	
	mock_entity.queue_free()
	action_bar.queue_free()
