# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_Hop5_SpriteVisibility_Fix.gd                                       ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Tests to verify entity sprites are visible on the battlefield and       ║
# ║ combat log displays proper entity names.                                ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑29                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

const BattleSceneResource = preload("res://scenes/battle/BattleScene.tscn")
const DetectiveScene = preload("res://scenes/entities/Detective.tscn")
const ImpScene = preload("res://scenes/entities/Imp.tscn")

var battle_scene: Node

func before_each():
	_ensure_registries_loaded()
	await get_tree().process_frame

func after_each():
	if battle_scene:
		battle_scene.queue_free()
		battle_scene = null

func _ensure_registries_loaded():
	"""Ensure all required registries are available"""
	var required_registries = ["AbilityReg", "BuffReg", "StatusReg"]
	
	for reg_name in required_registries:
		if not get_node_or_null("/root/" + reg_name):
			var reg_script = load("res://scripts/registries/" + reg_name + ".gd")
			var reg_instance = reg_script.new()
			reg_instance.name = reg_name
			get_tree().root.add_child(reg_instance)

func test_entities_are_node2d_types():
	"""Test that entities are properly structured as Node2D for positioning"""
	var detective = DetectiveScene.instantiate()
	var imp = ImpScene.instantiate()
	
	add_child_autoqfree(detective)
	add_child_autoqfree(imp)
	
	# Check entity structure
	print("Detective type: %s" % detective.get_class())
	print("Imp type: %s" % imp.get_class())
	
	# Check if they have Sprite2D children
	var detective_sprite = detective.get_node_or_null("Sprite2D")
	var imp_sprite = imp.get_node_or_null("Sprite2D")
	
	assert_not_null(detective_sprite, "Detective should have Sprite2D child")
	assert_not_null(imp_sprite, "Imp should have Sprite2D child")
	
	print("Detective sprite: %s" % detective_sprite)
	print("Imp sprite: %s" % imp_sprite)

func test_entity_sprites_have_textures():
	"""Test that entity sprites have proper textures loaded"""
	var detective = DetectiveScene.instantiate()
	var imp = ImpScene.instantiate()
	
	add_child_autoqfree(detective)
	add_child_autoqfree(imp)
	
	await get_tree().process_frame
	
	var detective_sprite = detective.get_node_or_null("Sprite2D")
	var imp_sprite = imp.get_node_or_null("Sprite2D")
	
	assert_not_null(detective_sprite.texture, "Detective sprite should have texture")
	assert_not_null(imp_sprite.texture, "Imp sprite should have texture")
	
	print("Detective texture: %s" % detective_sprite.texture)
	print("Imp texture: %s" % imp_sprite.texture)

func test_entity_positioning_on_grid():
	"""Test that entities are properly positioned when placed on grid"""
	battle_scene = BattleSceneResource.instantiate()
	add_child(battle_scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var battle_grid = battle_scene.get_node("World/BattleGrid")
	var entities = get_tree().get_nodes_in_group("entities")
	
	assert_gt(entities.size(), 0, "Should have spawned entities")
	
	for entity in entities:
		print("Entity %s:" % entity.name)
		print("  Type: %s" % entity.get_class())
		print("  On grid: %s" % battle_grid.is_entity_on_grid(entity))
		
		if entity is Node2D:
			print("  Position: %s" % (entity as Node2D).global_position)
		
		var sprite = entity.get_node_or_null("Sprite2D")
		if sprite:
			print("  Sprite visible: %s" % sprite.visible)
			print("  Sprite position: %s" % sprite.global_position)
			print("  Sprite texture: %s" % sprite.texture)

func test_combat_log_entity_names():
	"""Test that combat log displays proper entity names instead of 'Node'"""
	battle_scene = BattleSceneResource.instantiate()
	add_child(battle_scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	var battle_manager = battle_scene.get_node("BattleManager")
	var entities = get_tree().get_nodes_in_group("entities")
	
	assert_gt(entities.size(), 0, "Should have entities for testing")
	
	# Clear the log for clean test
	combat_log.clear()
	
	# Simulate a turn start event
	var test_entity = entities[0]
	battle_manager.emit_signal("turn_started", test_entity)
	
	await get_tree().process_frame
	
	var log_text = combat_log.get_text()
	print("Combat log text: %s" % log_text)
	
	# Check that log contains proper entity name, not "Node"
	assert_false(log_text.contains("Node's turn"), "Should not show 'Node's turn'")
	
	# Should show actual entity name
	var expected_names = ["Detective", "Imp"]
	var found_proper_name = false
	
	for entity_name in expected_names:
		if log_text.contains(entity_name + "'s turn"):
			found_proper_name = true
			break
	
	assert_true(found_proper_name, "Should show proper entity name in combat log")

func test_entity_display_names():
	"""Test that entities have proper display names accessible"""
	var detective = DetectiveScene.instantiate()
	var imp = ImpScene.instantiate()
	
	add_child_autoqfree(detective)
	add_child_autoqfree(imp)
	
	await get_tree().process_frame
	
	print("Detective name: %s" % detective.name)
	print("Imp name: %s" % imp.name)
	
	# Check if entities have data with display names
	if "data" in detective and detective.data:
		print("Detective data: %s" % detective.data)
		print("Detective display_name: %s" % detective.data.get("display_name", "NOT_FOUND"))
	
	if "data" in imp and imp.data:
		print("Imp data: %s" % imp.data)
		print("Imp display_name: %s" % imp.data.get("display_name", "NOT_FOUND"))

func test_sprite_visibility_after_grid_placement():
	"""Test that sprites remain visible after being placed on grid"""
	battle_scene = BattleSceneResource.instantiate()
	add_child(battle_scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var entities = get_tree().get_nodes_in_group("entities")
	
	for entity in entities:
		var sprite = entity.get_node_or_null("Sprite2D")
		if sprite:
			assert_true(sprite.visible, "%s sprite should be visible" % entity.name)
			assert_not_null(sprite.texture, "%s sprite should have texture" % entity.name)
			
			# Check that sprite is positioned somewhere reasonable (not at origin)
			var sprite_pos = sprite.global_position
			print("%s sprite position: %s" % [entity.name, sprite_pos])

#EOF
