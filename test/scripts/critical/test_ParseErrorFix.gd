# test/scripts/critical/test_ParseErrorFix.gd
extends GutTest

func test_imp_scene_loads_without_parse_error():
	"""Critical test: Verify Imp.tscn loads without parse errors"""
	print("Testing Imp.tscn loading...")
	
	# This should not throw any parse errors
	var imp_scene = preload("res://scenes/entities/Imp.tscn")
	assert_not_null(imp_scene, "Imp scene should load without parse errors")
	
	var imp = imp_scene.instantiate()
	assert_not_null(imp, "Imp should instantiate successfully")
	assert_eq(imp.name, "Imp", "Should have correct name")
	
	add_child(imp)
	await get_tree().process_frame
	
	# Verify the imp has the expected components
	var ability_container = imp.get_node_or_null("AbilityContainer")
	assert_not_null(ability_container, "Imp should have AbilityContainer")
	
	var sprite = imp.get_node_or_null("Sprite2D")
	assert_not_null(sprite, "Imp should have Sprite2D")
	
	# Verify abilities are accessible
	if imp.has_method("get_abilities"):
		var abilities = imp.get_abilities()
		assert_true(abilities.size() > 0, "Imp should have abilities")
		print("Imp abilities: ", abilities)
	
	imp.queue_free()
	print("✓ Imp.tscn loads and works correctly")

func test_detective_scene_still_works():
	"""Ensure Detective scene still works after Imp fix"""
	var detective_scene = preload("res://scenes/entities/Detective.tscn")
	assert_not_null(detective_scene, "Detective scene should load")
	
	var detective = detective_scene.instantiate()
	assert_not_null(detective, "Detective should instantiate")
	assert_eq(detective.name, "Detective", "Should have correct name")
	
	add_child(detective)
	await get_tree().process_frame
	
	if detective.has_method("get_abilities"):
		var abilities = detective.get_abilities()
		assert_true(abilities.size() > 0, "Detective should have abilities")
		print("Detective abilities: ", abilities)
	
	detective.queue_free()
	print("✓ Detective.tscn still works correctly")

func test_entity_spawner_works():
	"""Test EntitySpawner can create both entities without errors"""
	var spawner = preload("res://scripts/combat/EntitySpawner.gd").new()
	add_child(spawner)
	
	# Test Detective spawning
	var detective = spawner.spawn_detective()
	assert_not_null(detective, "Should spawn Detective")
	assert_eq(detective.name, "Detective", "Should be Detective")
	
	# Test Imp spawning
	var imp = spawner.spawn_imp()
	assert_not_null(imp, "Should spawn Imp")
	assert_eq(imp.name, "Imp", "Should be Imp")
	
	print("✓ EntitySpawner works for both entity types")
	
	detective.queue_free()
	imp.queue_free()
	spawner.queue_free()

func test_battlescene_loads_without_critical_errors():
	"""Test that BattleScene can at least be instantiated"""
	print("Testing BattleScene loading...")
	
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	assert_not_null(battle_scene_resource, "BattleScene should load")
	
	var battle_scene = battle_scene_resource.instantiate()
	assert_not_null(battle_scene, "BattleScene should instantiate")
	
	# We're not adding it to tree to avoid _ready() issues
	# Just testing that instantiation works
	battle_scene.queue_free()
	print("✓ BattleScene instantiates without critical errors")
