# test_Hop1_EntityPanel_acceptance.gd
extends GutTest
class_name TestHop1EntityPanelAcceptance

var battle_scene: BattleScene
var unit_card: UnitCard
var entity: Entity
var battle_manager: BattleManager

func before_each():
	# Load the full BattleScene to test integration
	var battle_scene_packed = preload("res://scenes/battle/BattleScene.tscn")
	battle_scene = battle_scene_packed.instantiate()
	add_child_autoqfree(battle_scene)
	
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Get references to key components
	unit_card = battle_scene.get_node("CanvasLayer/UI/UnitCard")
	battle_manager = battle_scene.get_node("BattleManager")
	
	# Find spawned entity
	var spawner = battle_scene.get_node("World/Spawner")
	entity = spawner.get_children().filter(func(n): return n is Entity)[0] if spawner.get_child_count() > 0 else null

func test_entity_panel_shows_detective_info():
	# ACCEPTANCE: Name/portrait match the Detective
	assert_not_null(unit_card, "UnitCard should exist in BattleScene")
	assert_not_null(unit_card.name_label, "Name label should be accessible")
	assert_not_null(unit_card.portrait, "Portrait should be accessible")
	
	if entity and entity.data:
		# Check that Detective information is shown
		var expected_name: String = ""
		if entity.data.display_name:
			expected_name = entity.data.display_name
		else:
			expected_name = entity.name
		assert_eq(unit_card.name_label.text, expected_name, "Should show correct entity name")
		assert_not_null(unit_card.portrait.texture, "Portrait should have texture")
		print("[TEST] ✓ Entity panel shows Detective info correctly")
	else:
		fail_test("Entity not found or lacks data")

func test_hp_bar_reflects_damage():
	# ACCEPTANCE: HP bar reflects damage when you call apply_damage()
	assert_not_null(unit_card.hp_bar, "HP bar should exist")
	
	if entity:
		var initial_hp = unit_card.hp_bar.value
		var initial_max = unit_card.hp_bar.max_value
		
		# Apply damage and check bar updates
		entity.apply_damage(5)
		
		assert_lt(unit_card.hp_bar.value, initial_hp, "HP bar should decrease after damage")
		assert_eq(unit_card.hp_bar.max_value, initial_max, "Max HP should remain constant")
		
		print("[TEST] ✓ HP bar reflects damage correctly - was: ", initial_hp, " now: ", unit_card.hp_bar.value)
	else:
		fail_test("Entity not found for damage test")

func test_unit_card_responds_to_turn_events():
	# ACCEPTANCE: Listen to BattleManager.turn_started(actor)
	assert_not_null(battle_manager, "BattleManager should exist")
	
	if entity:
		# Check that turn_started signal affects UnitCard visibility
		# Manually emit turn_started to test connection
		battle_manager.turn_started.emit(entity)
		
		# UnitCard should respond to turn events
		assert_true(unit_card.visible, "UnitCard should be visible during entity's turn")
		
		print("[TEST] ✓ UnitCard responds to turn events")
	else:
		fail_test("Entity not found for turn event test")

func test_logging_output():
	# ACCEPTANCE: Logs show [UI][UnitCard] bind …, update_hp …
	# This is verified by running the scene and checking console output
	# For automated testing, we verify the methods exist and are callable
	
	assert_true(unit_card.has_method("bind"), "UnitCard should have bind method")
	assert_true(unit_card.has_method("update_hp"), "UnitCard should have update_hp method")
	assert_true(unit_card.has_method("show_turn"), "UnitCard should have show_turn method")
	
	if entity:
		# Test that bind method works without error
		unit_card.bind(entity)
		
		# Test that update_hp works without error
		unit_card.update_hp(50, 100)
		assert_eq(unit_card.hp_bar.value, 50, "update_hp should set HP bar value")
		assert_eq(unit_card.hp_bar.max_value, 100, "update_hp should set HP bar max")
		
		print("[TEST] ✓ UnitCard methods work correctly")

func test_placement_in_battle_scene():
	# ACCEPTANCE: Place fixed top‑left in BattleScene (CanvasLayer/UI/UnitCard)
	var expected_path = "CanvasLayer/UI/UnitCard"
	var found_card = battle_scene.get_node_or_null(expected_path)
	
	assert_not_null(found_card, "UnitCard should be at " + expected_path)
	assert_true(found_card is UnitCard, "Node should be UnitCard type")
	assert_same(found_card, unit_card, "Should be the same UnitCard instance")
	
	print("[TEST] ✓ UnitCard placed correctly in BattleScene")

func after_each():
	assert_no_new_orphans()

# Helper to manually test console functionality
static func test_console_damage():
	print("[MANUAL TEST] To test console damage functionality:")
	print("1. Run BattleScene")
	print("2. Open debug console")
	print("3. Find entity: var entity = get_tree().get_first_node_in_group('entities')")
	print("4. Apply damage: entity.apply_damage(10)")
	print("5. Verify HP bar updates in UI")
#EOF
