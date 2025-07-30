# test/scripts/smoke/test_EntityLoading.gd
extends GutTest

func test_imp_scene_loads():
	"""Test that Imp.tscn can be loaded without errors"""
	var imp_scene = preload("res://scenes/entities/Imp.tscn")
	assert_not_null(imp_scene, "Imp scene should load")
	
	var imp = imp_scene.instantiate()
	assert_not_null(imp, "Imp should instantiate")
	add_child(imp)
	await get_tree().process_frame
	
	assert_eq(imp.name, "Imp", "Should have correct name")
	imp.queue_free()

func test_detective_scene_loads():
	"""Test that Detective.tscn can be loaded without errors"""
	var detective_scene = preload("res://scenes/entities/Detective.tscn")
	assert_not_null(detective_scene, "Detective scene should load")
	
	var detective = detective_scene.instantiate()
	assert_not_null(detective, "Detective should instantiate")
	add_child(detective)
	await get_tree().process_frame
	
	assert_eq(detective.name, "Detective", "Should have correct name")
	detective.queue_free()

func test_all_required_resources_exist():
	"""Test that all required resource files exist"""
	# Attack ability
	var attack = load("res://data/abilities/attack.tres")
	assert_not_null(attack, "Attack ability should exist")
	
	# Imp data
	var imp_data = load("res://data/entities/imp.tres")
	assert_not_null(imp_data, "Imp data should exist")
	
	# Detective data  
	var detective_data = load("res://data/entities/detective.tres")
	assert_not_null(detective_data, "Detective data should exist")
	
	# Sprites
	var imp_sprite = load("res://assets/entities/sprite_imp.png")
	assert_not_null(imp_sprite, "Imp sprite should exist")
	
	var detective_sprite = load("res://assets/entities/sprite_detective.png")
	assert_not_null(detective_sprite, "Detective sprite should exist")

func test_entity_spawner_loads():
	"""Test that EntitySpawner can load both entity types"""
	var spawner = preload("res://scripts/combat/EntitySpawner.gd").new()
	add_child(spawner)
	
	# Test spawning
	var detective = spawner.spawn_detective()
	assert_not_null(detective, "Should spawn Detective")
	assert_eq(detective.name, "Detective", "Should be Detective")
	
	var imp = spawner.spawn_imp()
	assert_not_null(imp, "Should spawn Imp")
	assert_eq(imp.name, "Imp", "Should be Imp")
	
	detective.queue_free()
	imp.queue_free()
	spawner.queue_free()

func test_battle_scene_loads():
	"""Test that BattleScene loads without critical errors"""
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	assert_not_null(battle_scene_resource, "BattleScene should load")
	
	var battle_scene = battle_scene_resource.instantiate()
	assert_not_null(battle_scene, "BattleScene should instantiate")
	
	# This is just a load test - we're not running _ready() yet
	battle_scene.queue_free()
