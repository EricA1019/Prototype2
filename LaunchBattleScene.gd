# ────────────────────────────────────────────────────────────────────
# LaunchBattleScene.gd  
# Runs the BattleScene directly to test UI components
# -------------------------------------------------------------------
extends SceneTree

func _initialize() -> void:
	print("[Launch] Loading BattleScene.tscn to test UI components...")
	change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _process(_delta: float) -> bool:
	# Let the scene run a few more frames to test UI initialization
	if Engine.get_frames_drawn() > 10:
		print("[Launch] BattleScene UI test complete. Exiting.")
		quit()
	return false
#EOF
