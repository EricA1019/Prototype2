# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_entity_launcher.gd                                                 ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for the LaunchBattleTest script. Tests scene loading and     ║
# ║ proper initialization behavior for headless testing.                    ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

func test_launch_battle_script_exists() -> void:
	var script = load("res://LaunchBattleTest.gd")
	assert_not_null(script, "LaunchBattleTest.gd should exist")
	assert_true(script is GDScript, "LaunchBattleTest.gd should be a GDScript")

func test_launch_script_extends_scene_tree() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	assert_true("extends SceneTree" in script_source, "LaunchBattleTest should extend SceneTree")

func test_test_host_scene_exists() -> void:
	var scene_path = "res://test/scenes/TestHost.tscn"
	var scene_exists = ResourceLoader.exists(scene_path)
	assert_true(scene_exists, "TestHost.tscn should exist at the expected path")

func test_launch_script_has_initialize_method() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	assert_true("func _initialize" in script_source, "Script should have _initialize method")

func test_launch_script_has_process_method() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	assert_true("func _process" in script_source, "Script should have _process method")

func test_launch_script_changes_scene() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	assert_true("change_scene_to_file" in script_source, "Script should call change_scene_to_file")
	assert_true("TestHost.tscn" in script_source, "Script should reference TestHost.tscn")

func test_launch_script_has_quit_logic() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	assert_true("quit()" in script_source, "Script should call quit()")
	assert_true("Engine.get_frames_drawn()" in script_source, "Script should check frames drawn")

func test_launch_script_proper_file_structure() -> void:
	var script = load("res://LaunchBattleTest.gd")
	var script_source = script.source_code
	# Check for proper structure elements
	assert_true("print(" in script_source, "Script should have print statements")
	assert_true("Loading TestHost.tscn" in script_source, "Script should log scene loading")
	assert_true("Done. Exiting." in script_source, "Script should log completion")

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
