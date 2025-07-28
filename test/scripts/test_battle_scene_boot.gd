extends "res://addons/gut/test.gd"

const Scene = preload("res://scenes/battle/BattleScene.tscn")

func test_battle_scene_boots_and_shows_one_portrait() -> void:
	var root = Scene.instantiate()
	add_child_autoqfree(root)
	await get_tree().process_frame
	# Find the InitiativeBar instance
	var bar = root.get_node("CanvasLayer/UI/InitiativeBar")
	assert_true(bar != null)
	# It should have exactly 1 portrait since we spawn one ally and no foes
	var ids = bar.get_order_ids()
	assert_eq(ids.size(), 1)

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
