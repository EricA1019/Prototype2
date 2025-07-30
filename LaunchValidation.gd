# LaunchValidation.gd
extends SceneTree

func _init():
	# Load validation scene
	var validation_scene = preload("res://scenes/debug/BattleSceneValidation.tscn").instantiate()
	root.add_child(validation_scene)
	
	# Run for a few seconds to see all output
	await create_timer(8.0).timeout
	
	print("Validation test completed - exiting")
	quit()
