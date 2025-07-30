# test/scripts/entities/test_EntityCreation.gd
extends GutTest

func test_detective_entity_creation():
	"""Test that Detective entity can be created with correct abilities"""
	var detective_scene = preload("res://scenes/entities/Detective.tscn")
	var detective = detective_scene.instantiate()
	add_child(detective)
	await get_tree().process_frame
	
	assert_not_null(detective, "Detective should instantiate")
	assert_eq(detective.name, "Detective", "Should have correct name")
	
	# Check abilities
	var abilities = detective.get_abilities()
	assert_true("Shield" in abilities, "Detective should have Shield")
	assert_true("Regen" in abilities, "Detective should have Regen")
	assert_eq(abilities.size(), 2, "Detective should have exactly 2 abilities")
	
	# Check team
	assert_eq(detective.get_team(), "friends", "Detective should be on friends team")
	
	detective.queue_free()

func test_imp_entity_creation():
	"""Test that Imp entity can be created with correct abilities"""
	var imp_scene = preload("res://scenes/entities/Imp.tscn")
	var imp = imp_scene.instantiate()
	add_child(imp)
	await get_tree().process_frame
	
	assert_not_null(imp, "Imp should instantiate")
	assert_eq(imp.name, "Imp", "Should have correct name")
	
	# Check abilities
	var abilities = imp.get_abilities()
	assert_true("Attack" in abilities, "Imp should have Attack")
	assert_true("Poison" in abilities, "Imp should have Poison")
	assert_true("Bleed" in abilities, "Imp should have Bleed")
	assert_eq(abilities.size(), 3, "Imp should have exactly 3 abilities")
	
	# Check team
	assert_eq(imp.get_team(), "foes", "Imp should be on foes team")
	
	imp.queue_free()

func test_entity_spawner_methods():
	"""Test EntitySpawner can spawn both entity types"""
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
	
	# Test legacy spawn (should spawn Detective)
	var legacy = spawner.spawn()
	assert_not_null(legacy, "Legacy spawn should work")
	assert_eq(legacy.name, "Detective", "Legacy spawn should be Detective")
	
	detective.queue_free()
	imp.queue_free()
	legacy.queue_free()
	spawner.queue_free()

func test_battlescene_with_real_entities():
	"""Test BattleScene works with real Detective and Imp entities"""
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify entities were spawned
	var entities = get_tree().get_nodes_in_group("entities")
	assert_eq(entities.size(), 2, "Should have 2 entities (Detective + Imp)")
	
	# Find Detective and Imp
	var detective = null
	var imp = null
	for entity in entities:
		if entity.name == "Detective":
			detective = entity
		elif entity.name == "Imp":
			imp = entity
	
	assert_not_null(detective, "Should find Detective")
	assert_not_null(imp, "Should find Imp")
	
	# Verify teams
	assert_eq(detective.get_team(), "friends", "Detective should be friend")
	assert_eq(imp.get_team(), "foes", "Imp should be foe")
	
	# Test ActionBar with Detective abilities
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var bm = battle_scene.get_node("BattleManager")
	
	bm.emit_signal("turn_started", detective)
	await get_tree().process_frame
	
	assert_true(action_bar.visible, "ActionBar should show for Detective")
	assert_eq(action_bar.get_ability_count(), 2, "Should show Detective's 2 abilities")
	
	# Test ActionBar with Imp abilities
	bm.emit_signal("turn_ended", detective)
	bm.emit_signal("turn_started", imp)
	await get_tree().process_frame
	
	assert_true(action_bar.visible, "ActionBar should show for Imp")
	assert_eq(action_bar.get_ability_count(), 3, "Should show Imp's 3 abilities")
	
	battle_scene.queue_free()
