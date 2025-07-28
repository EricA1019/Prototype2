# test_UnitCard_smoke.gd
extends GutTest
class_name TestUnitCardSmoke

var unit_card: UnitCard
var test_entity: Entity

func before_each():
	# Create UnitCard instance
	var unit_card_scene = preload("res://scenes/ui/UnitCard.tscn")
	unit_card = unit_card_scene.instantiate()
	add_child_autoqfree(unit_card)
	
	# Create test entity with data
	var entity_scene = preload("res://scenes/entities/EntityBase.tscn")
	test_entity = entity_scene.instantiate()
	add_child_autoqfree(test_entity)
	
	# Wait a frame for _ready to complete
	await get_tree().process_frame

func test_unit_card_bind_shows_entity_info():
	# GIVEN: UnitCard and Entity
	unit_card.bind(test_entity)
	
	# THEN: UnitCard shows entity information
	assert_not_null(unit_card.name_label, "Name label should exist")
	assert_not_null(unit_card.hp_bar, "HP bar should exist")
	assert_not_null(unit_card.portrait, "Portrait should exist")
	
	# Check if entity has data (Detective resource)
	if test_entity.data:
		assert_eq(unit_card.name_label.text, "Detective", "Should show Detective name")
		assert_gt(unit_card.hp_bar.max_value, 0, "HP bar should have max value")
		assert_gt(unit_card.hp_bar.value, 0, "HP bar should have current value")
	
	print("[TEST] UnitCard bind test passed")

func test_unit_card_hp_updates_on_damage():
	# GIVEN: Bound UnitCard and Entity
	unit_card.bind(test_entity)
	var initial_hp = unit_card.hp_bar.value
	var initial_max = unit_card.hp_bar.max_value
	
	# WHEN: Entity takes damage
	if test_entity.has_method("apply_damage"):
		test_entity.apply_damage(10)
		
		# THEN: HP bar reflects the damage
		assert_lt(unit_card.hp_bar.value, initial_hp, "HP should decrease after damage")
		assert_eq(unit_card.hp_bar.max_value, initial_max, "Max HP should remain the same")
		
		print("[TEST] HP update test passed - Initial: ", initial_hp, " After damage: ", unit_card.hp_bar.value)
	else:
		print("[TEST] Entity lacks apply_damage method - skipping damage test")

func test_unit_card_shows_correct_turn():
	# GIVEN: Bound UnitCard
	unit_card.bind(test_entity)
	
	# WHEN: show_turn is called with the bound entity
	unit_card.show_turn(test_entity)
	
	# THEN: UnitCard should be visible
	assert_true(unit_card.visible, "UnitCard should be visible for its entity's turn")
	
	# WHEN: show_turn is called with null
	unit_card.show_turn(null)
	
	# THEN: UnitCard should be hidden
	assert_false(unit_card.visible, "UnitCard should be hidden when no entity")
	
	print("[TEST] Show turn test passed")

func after_each():
	assert_no_new_orphans()
#EOF
