# test/scripts/ui/test_CombatLog_final_verification.gd
extends GutTest

func test_full_battle_sequence_with_combat_log():
	# Test a complete battle sequence with CombatLog
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	var bm = battle_scene.get_node("BattleManager")
	
	assert_not_null(combat_log, "CombatLog should exist")
	assert_not_null(bm, "BattleManager should exist")
	
	# Should have initial content (welcome message + battle events)
	assert_gt(combat_log.get_line_count(), 0, "Should have initial log entries")
	
	var initial_count = combat_log.get_line_count()
	print("Initial combat log entries: ", initial_count)
	print("Initial combat log content:\n", combat_log.get_text())
	
	# Simulate some battle events manually
	var entities = get_tree().get_nodes_in_group("Entity")
	if entities.size() > 0:
		var entity = entities[0]
		
		# Test damage logging
		var hp_before = entity.hp
		bm.damage(entity, 10, "Test")
		await get_tree().process_frame
		
		var hp_after = entity.hp
		assert_lt(hp_after, hp_before, "Entity should have taken damage")
		assert_gt(combat_log.get_line_count(), initial_count, "Should have logged damage")
		
		var log_text = combat_log.get_text()
		assert_true(log_text.contains("takes 10 damage"), "Should log damage event")
		
		print("After damage - combat log entries: ", combat_log.get_line_count())
		print("Combat log content:\n", combat_log.get_text())
	
	battle_scene.queue_free()

func test_combat_log_registry_integration():
	# Test that CombatLog receives signals from BuffReg
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	var bm = preload("res://scripts/combat/BattleManager.gd").new()
	
	add_child(combat_log)
	add_child(bm)
	await get_tree().process_frame
	
	# Connect signals
	bm.buff_applied.connect(combat_log._on_buff_applied)
	bm.status_applied.connect(combat_log._on_status_applied)
	bm.dot_tick.connect(combat_log._on_dot_tick)
	
	var initial_count = combat_log.get_line_count()
	
	# Test buff signal
	var mock_target = Node.new()
	mock_target.name = "TestTarget"
	bm.emit_signal("buff_applied", mock_target, "TestBuff")
	
	assert_eq(combat_log.get_line_count(), initial_count + 1, "Should log buff application")
	assert_true(combat_log.get_text().contains("TestTarget gains buff: TestBuff"), "Should contain buff message")
	
	# Test DOT signal
	bm.emit_signal("dot_tick", mock_target, 5, "Poison")
	
	assert_eq(combat_log.get_line_count(), initial_count + 2, "Should log DOT tick")
	assert_true(combat_log.get_text().contains("TestTarget takes 5 damage from Poison"), "Should contain DOT message")
	
	mock_target.queue_free()
	combat_log.queue_free()
	bm.queue_free()
