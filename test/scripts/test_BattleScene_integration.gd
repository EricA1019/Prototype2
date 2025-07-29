# test_BattleScene_integration.gd
extends GutTest
class_name TestBattleSceneIntegration

func test_battle_scene_loads_without_errors():
	# GIVEN: BattleScene resource
	var scene_path = "res://scenes/battle/BattleScene.tscn"
	assert_file_exists(scene_path)
	
	# WHEN: Loading the scene
	var scene_resource = load(scene_path)
	assert_not_null(scene_resource, "BattleScene should load successfully")
	
	# THEN: Scene can be instantiated
	var scene_instance = scene_resource.instantiate()
	assert_not_null(scene_instance, "BattleScene should instantiate successfully")
	
	# Add to tree and test basic functionality
	add_child_autoqfree(scene_instance)
	await get_tree().process_frame
	
	# Check required nodes exist
	assert_not_null(scene_instance.get_node_or_null("World"), "World node should exist")
	assert_not_null(scene_instance.get_node_or_null("World/Spawner"), "Spawner node should exist")
	assert_not_null(scene_instance.get_node_or_null("BattleManager"), "BattleManager should exist")
	assert_not_null(scene_instance.get_node_or_null("CanvasLayer/UI"), "UI should exist")

func test_entity_scene_loads_with_detective_data():
	# GIVEN: EntityBase scene
	var entity_scene_path = "res://scenes/entities/EntityBase.tscn"
	assert_file_exists(entity_scene_path)
	
	# WHEN: Loading and instantiating the entity
	var entity_resource = load(entity_scene_path)
	assert_not_null(entity_resource, "EntityBase should load successfully")
	
	var entity = entity_resource.instantiate()
	assert_not_null(entity, "EntityBase should instantiate successfully")
	
	add_child_autoqfree(entity)
	await get_tree().process_frame
	
	# THEN: Entity should have detective data loaded
	assert_not_null(entity.data, "Entity should have data loaded")
	if entity.data:
		assert_eq(entity.data.display_name, "Detective", "Should have detective data")
		assert_not_null(entity.data.stat_block, "Should have stat block")
		if entity.data.stat_block:
			assert_gt(entity.data.stat_block.hp_max, 0, "Should have valid HP")

func test_resource_registries_are_functional():
	# Test that resource registries work
	var ability_reg = get_node("/root/AbilityReg")
	assert_not_null(ability_reg, "AbilityReg should be available")
	
	var buff_reg = get_node("/root/BuffReg")
	assert_not_null(buff_reg, "BuffReg should be available")
	
	var status_reg = get_node("/root/StatusReg")
	assert_not_null(status_reg, "StatusReg should be available")
	
	# Check that some resources are registered
	if ability_reg.has_method("get_ability_names"):
		var abilities = ability_reg.get_ability_names()
		assert_gt(abilities.size(), 0, "Should have some abilities registered")
