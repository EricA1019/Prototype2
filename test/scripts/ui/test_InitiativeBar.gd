extends "res://addons/gut/test.gd"

func test_initiative_bar_script_exists() -> void:
	var script = load("res://scripts/ui/InitiativeBar.gd")
	assert_not_null(script, "InitiativeBar.gd should exist")
	assert_true(script is GDScript, "InitiativeBar.gd should be a GDScript")

func test_initiative_bar_scene_exists() -> void:
	var scene_path = "res://scenes/ui/InitiativeBar.tscn"
	var scene_exists = ResourceLoader.exists(scene_path)
	assert_true(scene_exists, "InitiativeBar.tscn should exist at the expected path")

func test_initiative_bar_extends_control() -> void:
	var script = load("res://scripts/ui/InitiativeBar.gd")
	var script_source = script.source_code
	assert_true("extends Control" in script_source, "InitiativeBar should extend Control")

func test_initiative_bar_has_required_methods() -> void:
	var script = load("res://scripts/ui/InitiativeBar.gd")
	var script_source = script.source_code
	assert_true("func bind(" in script_source, "InitiativeBar should have bind method")
	assert_true("func get_order_ids(" in script_source, "InitiativeBar should have get_order_ids method")
	assert_true("func populate(" in script_source, "InitiativeBar should have populate method")

func test_initiative_bar_has_required_signals() -> void:
	var script = load("res://scripts/ui/InitiativeBar.gd")
	var script_source = script.source_code
	assert_true("signal populated(" in script_source, "InitiativeBar should have populated signal")
	assert_true("signal highlighted(" in script_source, "InitiativeBar should have highlighted signal")

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
