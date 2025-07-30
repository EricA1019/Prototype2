# test/scripts/ui/test_ActionBar_integration.gd
extends GutTest

func test_action_bar_signal_emission():
	# Test that ActionBar properly emits ability_used signal
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Create mock entity
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.set("abilities", ["Shield"])
	
	# Set up signal watching
	watch_signals(action_bar)
	
	# Show action bar and simulate button press
	action_bar.show_for(mock_entity)
	
	# Get the button and simulate press
	var buttons = action_bar.button_container.get_children()
	assert_eq(buttons.size(), 1, "Should have one button")
	
	var shield_button = buttons[0]
	assert_eq(shield_button.text, "Shield", "Button should have correct text")
	
	# Simulate button press
	shield_button.emit_signal("pressed")
	await get_tree().process_frame
	
	# Verify signal was emitted
	assert_signal_emitted(action_bar, "ability_used", "Should emit ability_used signal")
	assert_signal_emitted_with_parameters(action_bar, "ability_used", [mock_entity, "Shield"], "Should emit with correct parameters")
	
	mock_entity.queue_free()
	action_bar.queue_free()

func test_battlemanager_use_ability():
	# Test BattleManager's use_ability method
	var bm = preload("res://scripts/combat/BattleManager.gd").new()
	add_child(bm)
	await get_tree().process_frame
	
	# Create mock actor with abilities
	var mock_actor = Node.new()
	mock_actor.name = "TestActor"
	mock_actor.set("team", "friends")
	
	# Create mock enemy for targeting
	var mock_enemy = Node.new()
	mock_enemy.name = "TestEnemy"
	mock_enemy.set("team", "foes")
	mock_enemy.set("hp", 100)
	
	# Set up battle manager with entities
	bm.initiative_queue = [mock_actor, mock_enemy]
	
	# Test self-targeting ability (Shield)
	bm.use_ability(mock_actor, "Shield")
	
	# Should not crash and should log the attempt
	# (Full integration depends on AbilityReg being available)
	
	mock_actor.queue_free()
	mock_enemy.queue_free()
	bm.queue_free()

func test_battlescene_action_bar_integration():
	# Test that BattleScene properly sets up ActionBar
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify ActionBar exists and is wired up
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	assert_not_null(action_bar, "ActionBar should exist in BattleScene")
	
	# Should start hidden until a turn starts
	assert_false(action_bar.visible, "ActionBar should start hidden")
	
	battle_scene.queue_free()

func test_full_action_bar_workflow():
	# Test complete workflow: BattleScene -> ActionBar -> BattleManager
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var bm = battle_scene.get_node("BattleManager")
	
	# Get the spawned entity
	var entities = get_tree().get_nodes_in_group("entities")
	if entities.size() > 0:
		var entity = entities[0]
		
		# Manually trigger turn_started to show action bar
		bm.emit_signal("turn_started", entity)
		await get_tree().process_frame
		
		# ActionBar should now be visible with buttons
		assert_true(action_bar.visible, "ActionBar should be visible during entity's turn")
		assert_gt(action_bar.get_ability_count(), 0, "Should have ability buttons for entity")
		
		# Test turn end hiding
		bm.emit_signal("turn_ended", entity)
		await get_tree().process_frame
		
		assert_false(action_bar.visible, "ActionBar should be hidden after turn ends")
	
	battle_scene.queue_free()
