# ────────────────────────────────────────────────────────────────────
# LaunchBattleTest.gd
# Runs the BattleTestScene via command line: godot4 -s this_script
# -------------------------------------------------------------------
extends SceneTree

func _initialize() -> void:
	print("[Launch] Loading TestHost.tscn …")
	change_scene_to_file("res://test/scenes/TestHost.tscn")

func _process(_delta: float) -> bool:
	# Let the scene run a couple of frames, then exit.
	if Engine.get_frames_drawn() > 2:
		print("[Launch] Done. Exiting.")
		quit()
	return false
#EOF
