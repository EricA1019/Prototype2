# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_BattleScene.gd                                                     ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for the BattleScene.tscn and BattleScene.gd. Tests scene    ║
# ║ structure, script references, and basic functionality.                  ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

const BattleSceneScene = preload("res://scenes/battle/BattleScene.tscn")

func test_battle_scene_exists() -> void:
	assert_not_null(BattleSceneScene, "BattleScene.tscn should exist")

func test_battle_scene_script_exists() -> void:
	var script = load("res://scripts/combat/BattleScene.gd")
	assert_not_null(script, "BattleScene.gd should exist")
	assert_true(script is GDScript, "BattleScene.gd should be a GDScript")

func test_battle_scene_instantiation() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	assert_not_null(scene_instance, "BattleScene should instantiate successfully")
	add_child_autoqfree(scene_instance)

func test_battle_scene_node_structure() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	add_child_autoqfree(scene_instance)

	# Check essential nodes exist
	assert_not_null(scene_instance.get_node("World"), "World node should exist")
	assert_not_null(scene_instance.get_node("World/Spawner"), "Spawner node should exist")
	assert_not_null(scene_instance.get_node("World/Camera2D"), "Camera2D node should exist")
	assert_not_null(scene_instance.get_node("BattleManager"), "BattleManager node should exist")
	assert_not_null(scene_instance.get_node("BattleManager/TurnManager"), "TurnManager node should exist")
	assert_not_null(scene_instance.get_node("CanvasLayer"), "CanvasLayer node should exist")
	assert_not_null(scene_instance.get_node("CanvasLayer/UI"), "UI node should exist")
	assert_not_null(scene_instance.get_node("CanvasLayer/UI/InitiativeBar"), "InitiativeBar node should exist")
	assert_not_null(scene_instance.get_node("CanvasLayer/UI/UnitCard"), "UnitCard node should exist")

func test_battle_scene_script_attachments() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	add_child_autoqfree(scene_instance)

	# Check that essential nodes have scripts attached
	var spawner = scene_instance.get_node("World/Spawner")
	assert_true(spawner.get_script() != null, "Spawner should have a script attached")

	var battle_manager = scene_instance.get_node("BattleManager")
	assert_true(battle_manager.get_script() != null, "BattleManager should have a script attached")

	var turn_manager = scene_instance.get_node("BattleManager/TurnManager")
	assert_true(turn_manager.get_script() != null, "TurnManager should have a script attached")

func test_camera_setup() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	add_child_autoqfree(scene_instance)

	var camera = scene_instance.get_node("World/Camera2D")
	assert_true(camera is Camera2D, "Camera should be a Camera2D node")
	assert_true(camera.current, "Camera should be set as current")

func test_initiative_bar_setup() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	add_child_autoqfree(scene_instance)

	var init_bar = scene_instance.get_node("CanvasLayer/UI/InitiativeBar")
	assert_true(init_bar.get_script() != null, "InitiativeBar should have a script attached")

	# Check that it has the required methods
	assert_true(init_bar.has_method("bind"), "InitiativeBar should have bind method")
	assert_true(init_bar.has_method("populate"), "InitiativeBar should have populate method")
	assert_true(init_bar.has_method("get_order_ids"), "InitiativeBar should have get_order_ids method")

func test_ui_control_layout() -> void:
	var scene_instance = BattleSceneScene.instantiate()
	add_child_autoqfree(scene_instance)

	var ui_control = scene_instance.get_node("CanvasLayer/UI")
	assert_true(ui_control is Control, "UI should be a Control node")
	assert_eq(ui_control.anchors_preset, Control.PRESET_FULL_RECT, "UI should use full rect preset")

func test_battle_scene_script_structure() -> void:
	var script = load("res://scripts/combat/BattleScene.gd")
	var script_source = script.source_code

	# Check for essential methods and properties
	assert_true("extends Node2D" in script_source, "BattleScene should extend Node2D")
	assert_true("func _ready(" in script_source, "BattleScene should have _ready method")
	assert_true("@onready var" in script_source, "BattleScene should use @onready variables")

func test_referenced_scripts_exist() -> void:
	# Test that all scripts referenced in the scene file exist
	assert_true(ResourceLoader.exists("res://scripts/combat/BattleScene.gd"), "BattleScene.gd should exist")
	assert_true(ResourceLoader.exists("res://scripts/combat/EntitySpawner.gd"), "EntitySpawner.gd should exist")
	assert_true(ResourceLoader.exists("res://scripts/combat/BattleManager.gd"), "BattleManager.gd should exist")
	assert_true(ResourceLoader.exists("res://scripts/combat/TurnManager.gd"), "TurnManager.gd should exist")

func test_referenced_scenes_exist() -> void:
	# Test that referenced scene files exist
	assert_true(ResourceLoader.exists("res://scenes/ui/InitiativeBar.tscn"), "InitiativeBar.tscn should exist")
	assert_true(ResourceLoader.exists("res://scenes/ui/UnitCard.tscn"), "UnitCard.tscn should exist")

# No orphan resources should appear
func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
