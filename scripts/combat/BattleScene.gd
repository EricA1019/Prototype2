# scripts/combat/BattleScene.gd
extends Node2D
class_name BattleScene

@onready var bm: Node          = $BattleManager
@onready var tm: Node          = $BattleManager/TurnManager
@onready var spawner: Node     = $World/Spawner
@onready var battle_grid: Node = $World/BattleGrid
@onready var bar: Control      = $CanvasLayer/UI/InitiativeBar
@onready var combat_log: Panel = $CanvasLayer/UI/CombatLog
@onready var action_bar: Panel = $CanvasLayer/UI/ActionBar

func _ready() -> void:
	print("[BattleScene] _ready - Setting up 6x6 grid battlefield")
	
	# Wait for battle grid to initialize
	await get_tree().process_frame
	
	# Reset spawner counters for clean battle setup
	if spawner.has_method("reset_spawn_counters"):
		spawner.reset_spawn_counters()
	
	# Spawn entities using new multi-spawn system for 2v2 battle
	var entity_configs = [
		{"type": "detective", "team": "friends", "is_large": false},
		{"type": "detective", "team": "friends", "is_large": false},  # Second ally
		{"type": "imp", "team": "foes", "is_large": false},
		{"type": "imp", "team": "foes", "is_large": false}  # Second enemy
	]
	
	print("[BattleScene] Spawning 2v2 battle configuration")
	var entities = spawner.spawn_multiple(entity_configs)
	
	if entities.size() < 4:
		push_warning("[BattleScene] Expected 4 entities, got %d" % entities.size())
		# Fallback to legacy 1v1 if multi-spawn fails
		print("[BattleScene] Falling back to legacy 1v1 spawn")
		var detective: Node = spawner.spawn_detective()
		var imp: Node = spawner.spawn_imp()
		entities = [detective, imp]
	
	# Separate allies and enemies
	var allies: Array[Node] = []
	var enemies: Array[Node] = []
	
	for entity in entities:
		var team = entity.get_team() if entity.has_method("get_team") else "friends"
		if team.to_lower() in ["friends", "allies"]:
			allies.append(entity)
		else:
			enemies.append(entity)
	
	print("[BattleScene] Team composition - Allies: %d, Enemies: %d" % [allies.size(), enemies.size()])
	
	if allies.is_empty() or enemies.is_empty():
		push_error("[BattleScene] Invalid team composition")
		return
	
	# Setup UI with first ally as primary
	var primary_ally = allies[0]
	
	# Bind InitiativeBar UI
	bar.fallback_icon = load("res://assets/missing_asset.png")
	bar.bind(bm)
	
	# Bind UnitCard UI
	var card = $CanvasLayer/UI/UnitCard
	card.bind(primary_ally)
	# Show card on this entity's turns
	bm.turn_started.connect(card.show_turn)
	
	# Bind CombatLog UI - connect all BattleManager signals
	_setup_combat_log()
	
	# Bind ActionBar UI - connect turn signals and ability usage
	_setup_action_bar()
	
	# Start battle with new team composition
	bm.start_battle(allies, enemies)
	
	# Force initial card display and ActionBar for testing
	card.show_turn(primary_ally)
	
	# Manually trigger turn_started to show ActionBar for demonstration
	await get_tree().process_frame
	bm.emit_signal("turn_started", primary_ally)
	
	# Focus camera on the grid center
	_focus_camera_on_grid()
	print("[BattleScene] Started %dv%d battle on 6x6 grid" % [allies.size(), enemies.size()])

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

func _focus_camera_on_grid() -> void:
	"""Focus camera on the center of the battle grid"""
	var cam: Camera2D = null
	for n in get_tree().get_nodes_in_group("Camera"):
		cam = n; break
	if cam == null:
		cam = get_tree().get_root().find_child("Camera2D", true, false)
	if cam == null:
		return
	
	# Position camera at grid center
	if battle_grid and battle_grid.has_method("grid_to_pixel"):
		var grid_center = Vector2i(3, 3)  # Center of 6x6 grid
		var pixel_center = battle_grid.grid_to_pixel(grid_center)
		cam.global_position = battle_grid.to_global(pixel_center)
		print("[BattleScene] Camera focused on grid center: %s" % cam.global_position)
	else:
		# Fallback to screen center
		var screen_center = get_viewport().get_visible_rect().size / 2
		cam.global_position = screen_center
		print("[BattleScene] Camera focused on screen center (fallback)")

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
