extends "res://addons/gut/test.gd"

func test_round_counter() -> void:
	var mgr := BattleManager.new()
	mgr.start_battle([], [])
	assert_eq(mgr.round, 1)
	mgr.queue_free()  # Clean up the node to prevent resource leaks
#EOF
