# test/scripts/integration/test_BattleScene_UI.gd
extends Node

# GUT-style integration tests for BattleScene UI

func before_each() -> void:
	# Ensure registry singletons are initialized
	var ability_reg = get_node_or_null("/root/AbilityReg")
	if ability_reg and ability_reg.list_names().size() == 0:
		ability_reg._bootstrap()

func test_action_bar_shows_three_buttons() -> void:
	var scene = load("res://scenes/battle/BattleScene.tscn").instantiate()
	get_tree().root.add_child(scene)
   # Wait one frame for scene _ready and signals
   await get_tree().process_frame

	# Path to button container
	var btn_container = scene.get_node("CanvasLayer/UI/ActionBar/VBoxContainer/ButtonContainer")
	assert_not_null(btn_container, "ButtonContainer not found in ActionBar")
	var count = btn_container.get_child_count()
	assert_eq(count, 3, "Expected 3 ability buttons (Shield, Regen, Shoot), got %d" % count)

func test_combat_log_records_actor_names() -> void:
	var scene = load("res://scenes/battle/BattleScene.tscn").instantiate()
   get_tree().root.add_child(scene)
   # Wait one frame for scene _ready and first signals
   await get_tree().process_frame

	# Look for a log entry containing "Detective's turn begins"
	var log_panel = scene.get_node("CanvasLayer/UI/CombatLog")
	assert_not_null(log_panel, "CombatLog panel not found")
	var log_text = log_panel.get_text()
	assert_true(log_text.find("Detective's turn begins") >= 0,
		"CombatLog should contain 'Detective's turn begins', got:\n%s" % log_text)

func test_theme_main_loads_without_errors() -> void:
	# Ensure custom theme can be loaded
	var theme = load("res://assets/themes/theme_main.tres")
	assert_not_null(theme, "theme_main.tres failed to load")
	assert_true(theme is Theme, "theme_main.tres did not return a Theme object")
