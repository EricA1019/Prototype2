# scripts/combat/BattleScene.gd
extends Node2D
class_name BattleScene

@onready var bm: Node          = $BattleManager
@onready var tm: Node          = $BattleManager/TurnManager
@onready var spawner: Node     = $World/Spawner
@onready var bar: Control      = $CanvasLayer/UI/InitiativeBar
@onready var combat_log: Panel = $CanvasLayer/UI/CombatLog
@onready var action_bar: Panel = $CanvasLayer/UI/ActionBar

func _ready() -> void:
	print("[BattleScene] _ready")
	# Spawn Detective ally
	var detective: Node = spawner.spawn_detective()
	if detective == null:
		push_warning("[BattleScene] Spawner returned null detective")
		return
	
	# Spawn Imp enemy
	var imp: Node = spawner.spawn_imp()
	if imp == null:
		push_warning("[BattleScene] Spawner returned null imp")
		return
	
	# Bind InitiativeBar UI
	bar.fallback_icon = load("res://assets/missing_asset.png")
	bar.bind(bm)
	
	# Bind UnitCard UI
	var card = $CanvasLayer/UI/UnitCard
	card.bind(detective)
	# Show card on this entity's turns
	bm.turn_started.connect(card.show_turn)
	
	# Bind CombatLog UI - connect all BattleManager signals
	_setup_combat_log()
	
	# Bind ActionBar UI - connect turn signals and ability usage
	_setup_action_bar()
	
	# Start battle with Detective vs Imp
	bm.start_battle([detective], [imp])
	
	# Force initial card display and ActionBar for testing
	card.show_turn(detective)
	
	# Manually trigger turn_started to show ActionBar for demonstration
	await get_tree().process_frame
	bm.emit_signal("turn_started", detective)
	
	# Focus camera on detective
	_focus_camera_on(detective)
	print("[BattleScene] Started battle: Detective vs Imp")

func _setup_combat_log() -> void:
	if not combat_log:
		push_warning("[BattleScene] CombatLog not found")
		return
	
	print("[BattleScene] Setting up CombatLog signal connections")
	
	# Connect all BattleManager signals to CombatLog
	bm.round_started.connect(combat_log._on_round_started)
	bm.turn_started.connect(combat_log._on_turn_started)
	bm.turn_ended.connect(combat_log._on_turn_ended)
	bm.damage_dealt.connect(combat_log._on_damage_dealt)
	bm.battle_ended.connect(combat_log._on_battle_ended)
	bm.status_applied.connect(combat_log._on_status_applied)
	bm.buff_applied.connect(combat_log._on_buff_applied)
	bm.dot_tick.connect(combat_log._on_dot_tick)
	
	# Add initial welcome message
	combat_log.append("Welcome to the battlefield!")

func _setup_action_bar() -> void:
	if not action_bar:
		push_warning("[BattleScene] ActionBar not found")
		return
	
	print("[BattleScene] Setting up ActionBar signal connections")
	
	# Connect BattleManager signals to ActionBar
	bm.turn_started.connect(action_bar.show_for)
	bm.turn_ended.connect(_on_turn_ended_hide_actions)
	
	# Connect ActionBar signals to BattleManager
	action_bar.ability_used.connect(bm.use_ability)

func _on_turn_ended_hide_actions(_actor: Node) -> void:
	"""Hide action bar when turn ends"""
	if action_bar:
		action_bar.hide_actions()

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
