# LaunchFinalTest.gd
extends SceneTree

func _init():
	# Load our test scene
	var test_scene = preload("res://scenes/debug/FinalBattleTest.tscn").instantiate()
	root.add_child(test_scene)
	
	# Keep running until test completes
	await process_frame
	await create_timer(5.0).timeout
	
	print("Test completed - exiting")
	quit()
