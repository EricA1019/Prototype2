# scripts/debug/TestBattleSceneLoad.gd
extends Node

func _ready():
	print("=== BattleScene Load Test ===")
	
	# Try loading all components individually first
	print("1. Testing individual components...")
	
	# Test Imp scene loading
	print("Loading Imp.tscn...")
	var imp_scene = preload("res://scenes/entities/Imp.tscn")
	var imp = imp_scene.instantiate()
	print("✓ Imp loaded: ", imp.name)
	
	# Test Detective scene loading  
	print("Loading Detective.tscn...")
	var detective_scene = preload("res://scenes/entities/Detective.tscn")
	var detective = detective_scene.instantiate()
	print("✓ Detective loaded: ", detective.name)
	
	# Test EntitySpawner
	print("Loading EntitySpawner...")
	var spawner = preload("res://scripts/combat/EntitySpawner.gd").new()
	print("✓ EntitySpawner loaded")
	
	# Test BattleScene loading (not instantiating yet)
	print("Loading BattleScene.tscn...")
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	print("✓ BattleScene resource loaded")
	
	print("\n2. Testing BattleScene instantiation...")
	
	# Now try instantiating BattleScene
	var battle_scene = battle_scene_resource.instantiate()
	print("✓ BattleScene instantiated")
	
	# Add to tree but don't call _ready yet
	add_child(battle_scene)
	print("✓ BattleScene added to tree")
	
	# Wait a frame to see if any errors occur
	await get_tree().process_frame
	print("✓ First frame processed")
	
	await get_tree().process_frame
	print("✓ Second frame processed")
	
	# Check if entities were spawned
	var entities = get_tree().get_nodes_in_group("entities")
	print("Entities found: ", entities.size())
	
	for entity in entities:
		print("  - %s (Team: %s, HP: %d)" % [entity.name, entity.get_team(), entity.hp])
	
	# Test ActionBar
	var action_bar = battle_scene.get_node_or_null("CanvasLayer/UI/ActionBar")
	if action_bar:
		print("✓ ActionBar found")
		print("  ActionBar visible: ", action_bar.visible)
	else:
		print("✗ ActionBar not found")
	
	# Test BattleManager
	var bm = battle_scene.get_node_or_null("BattleManager")
	if bm:
		print("✓ BattleManager found")
	else:
		print("✗ BattleManager not found")
	
	print("\n=== Load Test Complete ===")
	print("If you see this message, the BattleScene loaded successfully!")
	
	# Clean up
	imp.queue_free()
	detective.queue_free()
	spawner.queue_free()
