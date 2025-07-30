# scripts/debug/SimpleEntityTest.gd
extends Node

func _ready():
	print("=== Simple Entity Test ===")
	
	# Test 1: Load Imp scene
	print("1. Testing Imp.tscn...")
	var imp_scene = load("res://scenes/entities/Imp.tscn")
	if imp_scene == null:
		print("✗ Failed to load Imp.tscn")
		return
	else:
		print("✓ Imp.tscn loaded successfully")
	
	var imp = imp_scene.instantiate()
	if imp == null:
		print("✗ Failed to instantiate Imp")
		return
	else:
		print("✓ Imp instantiated successfully")
	
	add_child(imp)
	await get_tree().process_frame
	
	if imp.has_method("get_abilities"):
		var abilities = imp.get_abilities()
		print("✓ Imp abilities: ", abilities)
	else:
		print("✗ Imp missing get_abilities method")
	
	# Test 2: Load Detective scene
	print("2. Testing Detective.tscn...")
	var detective_scene = load("res://scenes/entities/Detective.tscn")
	if detective_scene == null:
		print("✗ Failed to load Detective.tscn")
		return
	else:
		print("✓ Detective.tscn loaded successfully")
	
	var detective = detective_scene.instantiate()
	if detective == null:
		print("✗ Failed to instantiate Detective")
		return
	else:
		print("✓ Detective instantiated successfully")
	
	add_child(detective)
	await get_tree().process_frame
	
	if detective.has_method("get_abilities"):
		var abilities = detective.get_abilities()
		print("✓ Detective abilities: ", abilities)
	else:
		print("✗ Detective missing get_abilities method")
	
	# Test 3: EntitySpawner
	print("3. Testing EntitySpawner...")
	var spawner = preload("res://scripts/combat/EntitySpawner.gd").new()
	add_child(spawner)
	
	var spawned_detective = spawner.spawn_detective()
	if spawned_detective:
		print("✓ EntitySpawner.spawn_detective() works")
	else:
		print("✗ EntitySpawner.spawn_detective() failed")
	
	var spawned_imp = spawner.spawn_imp()
	if spawned_imp:
		print("✓ EntitySpawner.spawn_imp() works")
	else:
		print("✗ EntitySpawner.spawn_imp() failed")
	
	print("\n=== Test Results ===")
	print("If all tests show ✓, entities are working correctly!")
	print("Ready to test BattleScene integration.")
