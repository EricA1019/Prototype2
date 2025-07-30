# test/scripts/debug/test_UIErrorFix.gd
extends GutTest

func test_initiative_bar_outline_style_fix():
	"""Test that InitiativeBar _outline_style method works without errors"""
	var initiative_bar_scene = preload("res://scenes/ui/InitiativeBar.tscn")
	var initiative_bar = initiative_bar_scene.instantiate()
	add_child(initiative_bar)
	await get_tree().process_frame
	
	# Test the _outline_style method directly
	if initiative_bar.has_method("_outline_style"):
		var style = initiative_bar._outline_style()
		assert_not_null(style, "Should create StyleBoxFlat without errors")
		assert_true(style is StyleBoxFlat, "Should be StyleBoxFlat")
		print("✓ InitiativeBar _outline_style works correctly")
	
	initiative_bar.queue_free()

func test_action_bar_ui_creation():
	"""Test ActionBar UI component creation without VBox/HBox errors"""
	print("Testing ActionBar UI creation...")
	
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Verify structure
	var vbox = action_bar.get_node_or_null("VBox")
	assert_not_null(vbox, "VBox should exist")
	
	var button_container = action_bar.get_node_or_null("VBox/ButtonContainer")
	assert_not_null(button_container, "ButtonContainer (HBox) should exist")
	assert_true(button_container is HBoxContainer, "Should be HBoxContainer")
	
	# Test button creation
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.set("abilities", ["TestAbility"])
	
	action_bar.show_for(mock_entity)
	await get_tree().process_frame
	
	assert_eq(action_bar.get_ability_count(), 1, "Should create 1 button")
	print("✓ ActionBar UI creation works correctly")
	
	mock_entity.queue_free()
	action_bar.queue_free()

func test_combat_log_ui_creation():
	"""Test CombatLog UI component creation"""
	print("Testing CombatLog UI creation...")
	
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	add_child(combat_log)
	await get_tree().process_frame
	
	# Verify structure
	var vbox = combat_log.get_node_or_null("VBox")
	assert_not_null(vbox, "VBox should exist")
	
	var scroll_container = combat_log.get_node_or_null("VBox/ScrollContainer")
	assert_not_null(scroll_container, "ScrollContainer should exist")
	
	print("✓ CombatLog UI creation works correctly")
	
	combat_log.queue_free()

func test_all_ui_components_together():
	"""Test all UI components can be created together without conflicts"""
	print("Testing all UI components together...")
	
	# Create all UI components
	var action_bar = preload("res://scenes/ui/ActionBar.tscn").instantiate()
	var combat_log = preload("res://scenes/ui/CombatLog.tscn").instantiate()
	var initiative_bar = preload("res://scenes/ui/InitiativeBar.tscn").instantiate()
	var unit_card = preload("res://scenes/ui/UnitCard.tscn").instantiate()
	
	add_child(action_bar)
	add_child(combat_log)
	add_child(initiative_bar)
	add_child(unit_card)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ All UI components created successfully")
	
	action_bar.queue_free()
	combat_log.queue_free()
	initiative_bar.queue_free()
	unit_card.queue_free()

func test_battle_scene_with_fixed_ui():
	"""Test BattleScene with all UI fixes applied"""
	print("Testing BattleScene with UI fixes...")
	
	# Manually initialize registries for test
	var ability_reg = preload("res://scripts/registries/AbilityReg.gd").new()
	ability_reg.name = "AbilityReg"
	get_node("/root").add_child(ability_reg)
	
	var buff_reg = preload("res://scripts/registries/BuffReg.gd").new()
	buff_reg.name = "BuffReg"
	get_node("/root").add_child(buff_reg)
	
	var status_reg = preload("res://scripts/registries/StatusReg.gd").new()
	status_reg.name = "StatusReg"
	get_node("/root").add_child(status_reg)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Now test BattleScene
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	# Add but don't trigger full initialization yet
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that UI components exist and are functional
	var action_bar = battle_scene.get_node_or_null("CanvasLayer/UI/ActionBar")
	var combat_log = battle_scene.get_node_or_null("CanvasLayer/UI/CombatLog")
	var initiative_bar = battle_scene.get_node_or_null("CanvasLayer/UI/InitiativeBar")
	
	assert_not_null(action_bar, "ActionBar should exist in BattleScene")
	assert_not_null(combat_log, "CombatLog should exist in BattleScene")
	assert_not_null(initiative_bar, "InitiativeBar should exist in BattleScene")
	
	print("✓ BattleScene UI components all working")
	
	battle_scene.queue_free()
	ability_reg.queue_free()
	buff_reg.queue_free()
	status_reg.queue_free()
