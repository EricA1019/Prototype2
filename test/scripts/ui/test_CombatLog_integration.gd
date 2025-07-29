# test/scripts/ui/test_CombatLog_integration.gd
extends GutTest

func test_combat_log_battlemanager_integration():
	# Test that CombatLog properly receives signals from BattleManager
	var bm = preload("res://scripts/combat/BattleManager.gd").new()
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	
	add_child(bm)
	add_child(combat_log)
	await get_tree().process_frame
	
	# Connect signals manually (normally done in BattleScene)
	bm.round_started.connect(combat_log._on_round_started)
	bm.turn_started.connect(combat_log._on_turn_started)
	bm.turn_ended.connect(combat_log._on_turn_ended)
	bm.damage_dealt.connect(combat_log._on_damage_dealt)
	bm.battle_ended.connect(combat_log._on_battle_ended)
	
	# Test signal emissions
	bm.emit_signal("round_started", 1)
	assert_eq(combat_log.get_line_count(), 1, "Should receive round_started signal")
	
	var mock_actor = Node.new()
	mock_actor.name = "Hero"
	bm.emit_signal("turn_started", mock_actor)
	assert_eq(combat_log.get_line_count(), 2, "Should receive turn_started signal")
	
	bm.emit_signal("turn_ended", mock_actor)
	assert_eq(combat_log.get_line_count(), 3, "Should receive turn_ended signal")
	
	# Test damage signal
	var mock_target = Node.new()
	mock_target.name = "Enemy"
	bm.emit_signal("damage_dealt", mock_actor, mock_target, 15, "Fire")
	assert_eq(combat_log.get_line_count(), 4, "Should receive damage_dealt signal")
	
	var log_text = combat_log.get_text()
	assert_true(log_text.contains("ROUND 1 STARTED"), "Should log round start")
	assert_true(log_text.contains("Hero's turn begins"), "Should log turn start")
	assert_true(log_text.contains("Hero's turn ends"), "Should log turn end")
	assert_true(log_text.contains("Hero deals 15 Fire damage to Enemy"), "Should log damage")
	
	mock_actor.queue_free()
	mock_target.queue_free()
	combat_log.queue_free()
	bm.queue_free()

func test_battlescene_with_combat_log():
	# Test that BattleScene properly sets up CombatLog
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	
	# Verify CombatLog exists and is wired up
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	assert_not_null(combat_log, "CombatLog should exist in BattleScene")
	
	# Should have at least the welcome message
	assert_gt(combat_log.get_line_count(), 0, "CombatLog should have initial content")
	
	var log_text = combat_log.get_text()
	assert_true(log_text.contains("Welcome to the battlefield"), "Should have welcome message")
	
	battle_scene.queue_free()

func test_battle_sequence_logging():
	# Test a full battle sequence and verify all events are logged
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	var bm = battle_scene.get_node("BattleManager")
	
	# Clear initial messages for clean test
	combat_log.clear()
	
	# Simulate some battle events
	var mock_entity = Node.new()
	mock_entity.name = "TestEntity"
	mock_entity.hp = 100
	mock_entity.team = "friends"
	
	# Add mock methods to entity
	mock_entity.set_script(preload("res://test/scripts/helpers/MockEntity.gd"))
	
	# Test damage method
	bm.damage(mock_entity, 25, "Physical")
	
	# Should have logged the damage
	assert_gt(combat_log.get_line_count(), 0, "Should log damage events")
	
	var log_text = combat_log.get_text()
	assert_true(log_text.contains("TestEntity"), "Should mention the entity name")
	assert_true(log_text.contains("25"), "Should mention damage amount")
	
	mock_entity.queue_free()
	battle_scene.queue_free()
