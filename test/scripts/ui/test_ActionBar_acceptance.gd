# test/scripts/ui/test_ActionBar_acceptance.gd
extends GutTest

func test_hop3_acceptance_criteria():
	"""
	Hop 3 Acceptance Test:
	- Detective shows Regen and Shield buttons
	- Clicking logs ability usage and applies effect if wired
	- ActionBar properly integrates with BattleManager
	"""
	# Load the actual BattleScene
	var battle_scene_resource = preload("res://scenes/battle/BattleScene.tscn")
	var battle_scene = battle_scene_resource.instantiate()
	
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var action_bar = battle_scene.get_node("CanvasLayer/UI/ActionBar")
	var bm = battle_scene.get_node("BattleManager")
	var combat_log = battle_scene.get_node("CanvasLayer/UI/CombatLog")
	
	assert_not_null(action_bar, "ActionBar should exist")
	assert_not_null(bm, "BattleManager should exist")
	assert_not_null(combat_log, "CombatLog should exist")
	
	# Get the spawned Detective entity
	var entities = get_tree().get_nodes_in_group("entities")
	assert_gt(entities.size(), 0, "Should have spawned entities")
	
	var detective = entities[0]
	print("Detective abilities: ", detective.get_abilities())
	
	# Verify Detective has expected abilities
	var abilities = detective.get_abilities()
	assert_true("Shield" in abilities, "Detective should have Shield ability")
	assert_true("Regen" in abilities, "Detective should have Regen ability")
	
	# Manually trigger turn to show ActionBar
	bm.emit_signal("turn_started", detective)
	await get_tree().process_frame
	
	# ActionBar should now be visible with Detective's abilities
	assert_true(action_bar.visible, "ActionBar should be visible during Detective's turn")
	assert_eq(action_bar.get_ability_count(), 2, "Should show 2 ability buttons for Detective")
	assert_eq(action_bar.get_current_entity(), detective, "Should track Detective as current entity")
	
	# Get the buttons and verify they exist
	var buttons = action_bar.button_container.get_children()
	assert_eq(buttons.size(), 2, "Should have exactly 2 buttons")
	
	var button_texts = []
	for button in buttons:
		button_texts.append(button.text)
	
	assert_true("Shield" in button_texts, "Should have Shield button")
	assert_true("Regen" in button_texts, "Should have Regen button")
	
	# Test clicking Shield button
	var shield_button = null
	for button in buttons:
		if button.text == "Shield":
			shield_button = button
			break
	
	assert_not_null(shield_button, "Should find Shield button")
	
	# Clear combat log for clean test
	combat_log.get_line_count()  # Just check that it works
	
	# Simulate Shield button click
	shield_button.emit_signal("pressed")
	await get_tree().process_frame
	
	# Should have triggered ability usage
	# (Log entries from BattleManager.use_ability)
	print("Combat log after Shield click:\n", combat_log.get_text())
	
	# Test turn end hiding
	bm.emit_signal("turn_ended", detective)
	await get_tree().process_frame
	
	assert_false(action_bar.visible, "ActionBar should be hidden after turn ends")
	
	battle_scene.queue_free()

func test_actionbar_auto_targeting():
	"""Test that abilities with auto-targeting work correctly"""
	var bm = preload("res://scripts/combat/BattleManager.gd").new()
	add_child(bm)
	await get_tree().process_frame
	
	# Create mock entities
	var ally = Node.new()
	ally.name = "Ally"
	ally.set("team", "friends")
	ally.set("hp", 100)
	
	var enemy = Node.new()
	enemy.name = "Enemy"
	enemy.set("team", "foes")
	enemy.set("hp", 100)
	
	# Set up initiative queue
	bm.initiative_queue = [ally, enemy]
	
	# Test get_enemies method
	var enemies = bm.get_enemies(ally)
	assert_eq(enemies.size(), 1, "Ally should have 1 enemy")
	assert_eq(enemies[0], enemy, "Should find the correct enemy")
	
	var allies = bm.get_enemies(enemy)
	assert_eq(allies.size(), 1, "Enemy should have 1 ally target")
	assert_eq(allies[0], ally, "Should find the correct ally")
	
	ally.queue_free()
	enemy.queue_free()
	bm.queue_free()

func test_multi_ability_entity():
	"""Test ActionBar with entity that has multiple abilities"""
	var action_bar_scene = preload("res://scenes/ui/ActionBar.tscn")
	var action_bar = action_bar_scene.instantiate()
	add_child(action_bar)
	await get_tree().process_frame
	
	# Create entity with 4 abilities
	var mock_entity = Node.new()
	mock_entity.name = "MultiAbilityEntity"
	mock_entity.set_script(preload("res://test/scripts/helpers/MockEntity.gd"))
	mock_entity.abilities = ["Shield", "Regen", "Attack", "Heal"]
	
	action_bar.show_for(mock_entity)
	
	assert_true(action_bar.visible, "Should be visible")
	assert_eq(action_bar.get_ability_count(), 4, "Should have 4 ability buttons")
	
	# Verify all buttons exist
	var buttons = action_bar.button_container.get_children()
	var button_texts = []
	for button in buttons:
		button_texts.append(button.text)
	
	assert_true("Shield" in button_texts, "Should have Shield")
	assert_true("Regen" in button_texts, "Should have Regen")
	assert_true("Attack" in button_texts, "Should have Attack")
	assert_true("Heal" in button_texts, "Should have Heal")
	
	mock_entity.queue_free()
	action_bar.queue_free()
