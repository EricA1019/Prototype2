# TestDetectiveAbilities.gd
# Direct test for Detective abilities
extends SceneTree

func _initialize() -> void:
	print("[Test] Loading Detective scene...")
	var detective_scene = load("res://scenes/entities/Detective.tscn")
	var detective = detective_scene.instantiate()
	print("[Test] Detective instantiated")
	
	# Add to scene tree so _ready() gets called
	var scene_root = current_scene
	if scene_root == null:
		scene_root = Node.new()
		current_scene = scene_root
	scene_root.add_child(detective)
	# Bootstrap CombatLog UI for test output
	var combat_log = load("res://scenes/ui/CombatLog.tscn").instantiate() as Node
	scene_root.add_child(combat_log)
	combat_log.append("[Test] Loading Detective scene...")
	combat_log.append("[Test] Detective instantiated")
	
	# Process one frame to allow _ready() to be called
	await process_frame
	
	# Check abilities
	var abilities = detective.get_abilities() if detective.has_method("get_abilities") else []
	print("[Test] Detective abilities: %s" % str(abilities))
	print("[Test] Total abilities: %d" % abilities.size())
	
	# Exit
	quit()

func _process(_delta: float) -> bool:
	return false
