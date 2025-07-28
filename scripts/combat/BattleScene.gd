# scripts/combat/BattleScene.gd
extends Node2D
class_name BattleScene

@onready var bm: Node          = $BattleManager
@onready var tm: Node          = $BattleManager/TurnManager
@onready var spawner: Node     = $World/Spawner
@onready var bar: Control      = $CanvasLayer/UI/InitiativeBar

func _ready() -> void:
	print("[BattleScene] _ready")
	# Spawn one ally entity
	var ally: Node = spawner.spawn()
	if ally == null:
		push_warning("[BattleScene] Spawner returned null")
		return
	# Bind InitiativeBar UI
	bar.fallback_icon = load("res://assets/missing_asset.png")
	bar.bind(bm)
	# Bind UnitCard UI
	var card = $CanvasLayer/UI/UnitCard
	card.bind(ally)
	# Show card on this entity's turns
	bm.turn_started.connect(card.show_turn)
	# Start battle with one friend, no foes
	bm.start_battle([ally], [])
	# Force initial card display
	card.show_turn(ally)
	# Focus camera on ally
	_focus_camera_on(ally)
	print("[BattleScene] Started battle with 1 unit")

func _focus_camera_on(entity: Node) -> void:
	var cam: Camera2D = null
	for n in get_tree().get_nodes_in_group("Camera"):
		cam = n; break
	if cam == null:
		cam = get_tree().get_root().find_child("Camera2D", true, false)
	if cam == null:
		return
	var pos := Vector2.ZERO
	var spr: Node = entity.get_node_or_null("Sprite2D")
	if spr and spr is Node2D:
		pos = (spr as Node2D).global_position
	elif entity is Node2D:
		pos = (entity as Node2D).global_position
	cam.position = pos
#EOF
