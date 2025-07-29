# test/scripts/ui/test_CombatLog_smoke.gd
extends GutTest

func test_combat_log_creation():
	# Test that CombatLog can be instantiated
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	
	assert_not_null(combat_log, "CombatLog should instantiate")
	assert_true(combat_log is Panel, "CombatLog should be a Panel")
	
	# Add to scene tree for proper initialization
	add_child(combat_log)
	await get_tree().process_frame
	
	assert_not_null(combat_log.rich_text_label, "RichTextLabel should be found")
	assert_not_null(combat_log.scroll_container, "ScrollContainer should be found")
	
	combat_log.queue_free()

func test_combat_log_append_and_clear():
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	add_child(combat_log)
	await get_tree().process_frame
	
	# Test initial state
	assert_eq(combat_log.get_line_count(), 0, "Initial line count should be 0")
	
	# Test append
	combat_log.append("Test message 1")
	assert_eq(combat_log.get_line_count(), 1, "Line count should be 1 after first append")
	
	combat_log.append("Test message 2")
	assert_eq(combat_log.get_line_count(), 2, "Line count should be 2 after second append")
	
	# Test that text contains our messages
	var log_text = combat_log.get_text()
	assert_true(log_text.contains("Test message 1"), "Log should contain first message")
	assert_true(log_text.contains("Test message 2"), "Log should contain second message")
	
	# Test clear
	combat_log.clear()
	assert_eq(combat_log.get_line_count(), 0, "Line count should be 0 after clear")
	
	combat_log.queue_free()

func test_combat_log_signal_handlers():
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	add_child(combat_log)
	await get_tree().process_frame
	
	# Test round started
	combat_log._on_round_started(1)
	assert_eq(combat_log.get_line_count(), 1, "Should have 1 line after round started")
	assert_true(combat_log.get_text().contains("ROUND 1 STARTED"), "Should contain round started message")
	
	# Test turn started
	var mock_actor = Node.new()
	mock_actor.name = "TestActor"
	combat_log._on_turn_started(mock_actor)
	assert_eq(combat_log.get_line_count(), 2, "Should have 2 lines after turn started")
	assert_true(combat_log.get_text().contains("TestActor's turn begins"), "Should contain turn started message")
	
	# Test damage dealt
	var mock_target = Node.new()
	mock_target.name = "TestTarget"
	combat_log._on_damage_dealt(mock_actor, mock_target, 10, "Physical")
	assert_eq(combat_log.get_line_count(), 3, "Should have 3 lines after damage dealt")
	assert_true(combat_log.get_text().contains("TestActor deals 10 Physical damage to TestTarget"), "Should contain damage message")
	
	# Test battle ended
	combat_log._on_battle_ended("victory")
	assert_eq(combat_log.get_line_count(), 4, "Should have 4 lines after battle ended")
	assert_true(combat_log.get_text().contains("BATTLE ENDED: VICTORY"), "Should contain battle ended message")
	
	mock_actor.queue_free()
	mock_target.queue_free()
	combat_log.queue_free()

func test_combat_log_null_safety():
	var combat_log_scene = preload("res://scenes/ui/CombatLog.tscn")
	var combat_log = combat_log_scene.instantiate()
	add_child(combat_log)
	await get_tree().process_frame
	
	# Test with null actors - should not crash
	combat_log._on_turn_started(null)
	assert_eq(combat_log.get_line_count(), 1, "Should handle null actor gracefully")
	assert_true(combat_log.get_text().contains("Unknown's turn begins"), "Should show Unknown for null actor")
	
	combat_log._on_damage_dealt(null, null, 5, "Magic")
	assert_eq(combat_log.get_line_count(), 2, "Should handle null attacker/target gracefully")
	assert_true(combat_log.get_text().contains("Unknown deals 5 Magic damage to Unknown"), "Should show Unknown for null entities")
	
	combat_log.queue_free()
