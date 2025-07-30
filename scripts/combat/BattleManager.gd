# ────────────────────────────────────────────────────────────────────
# BattleManager.gd — Drives rounds & turns for side‑view combat
# ------------------------------------------------------------------
extends Node
class_name BattleManager

# Existing signals
signal turn_order_built(units:Array)
signal turn_ended(actor:Node)
signal turn_started(actor:Node)
signal battle_ended(result)

# New signals for Combat Log
signal round_started(round_number:int)
signal damage_dealt(attacker:Node, target:Node, amount:int, dtype:String)
signal status_applied(target:Node, status_name:String)
signal buff_applied(target:Node, buff_name:String)
signal dot_tick(target:Node, damage:int, effect_name:String)

var tm: Node = null   # TurnManager
var current_round: int = 0
var initiative_queue: Array = []
@export var max_rounds: int = 100  # cap at 100 rounds to avoid endless loops (set -1 for no cap)

func _ready() -> void:
	# Connect to registry signals to forward them
	_connect_to_registries()

func _connect_to_registries() -> void:
	# Connect BuffReg signals
	var buff_reg = get_node_or_null("/root/BuffReg")
	if buff_reg:
		if not buff_reg.buff_applied.is_connected(_on_buff_reg_buff_applied):
			buff_reg.buff_applied.connect(_on_buff_reg_buff_applied)
		if not buff_reg.tick_damage.is_connected(_on_buff_reg_tick_damage):
			buff_reg.tick_damage.connect(_on_buff_reg_tick_damage)
	
	# Connect StatusReg signals if available
	var status_reg = get_node_or_null("/root/StatusReg")
	if status_reg and status_reg.has_signal("status_applied"):
		if not status_reg.status_applied.is_connected(_on_status_reg_status_applied):
			status_reg.status_applied.connect(_on_status_reg_status_applied)

# Signal forwarding methods
func _on_buff_reg_buff_applied(target: Node, buff_name: String, _stacks: int, _duration: int) -> void:
	emit_signal("buff_applied", target, buff_name)

func _on_buff_reg_tick_damage(target: Node, buff_name: String, amount: int, _damage_type: String) -> void:
	emit_signal("dot_tick", target, amount, buff_name)

func _on_status_reg_status_applied(target: Node, status_name: String) -> void:
	emit_signal("status_applied", target, status_name)

# Getter method for round access (avoiding shadowing built-in function)
func get_round() -> int:
	return current_round

func start_battle(friends: Array, foes: Array) -> void:
	# ensure StatusReg is autoloaded under /root for tests
	if not get_tree().root.has_node("StatusReg"):
		var sr = preload("res://scripts/registries/StatusReg.gd").new()
		sr.name = "StatusReg"
		get_tree().root.add_child(sr)

	print("[CombatMgr] Starting battle …")
	current_round = 1
	_rebuild_queue(friends + foes)
	
	# Check victory before starting
	if _check_victory():
		emit_signal("battle_ended", "victory")
		return
	
	# Loop until victory or max_rounds if set
	while not _check_victory() and (max_rounds < 0 or current_round < max_rounds):
		_run_round()
		current_round += 1
			
	emit_signal("battle_ended", "victory")

func _rebuild_queue(units: Array) -> void:
	initiative_queue = units.duplicate()
	if tm:
		tm.build_initiative(initiative_queue)
	else:
		initiative_queue.sort_custom(func(a, b): return a.speed > b.speed)
	print("[CombatMgr] Initiative order:", initiative_queue)
	emit_signal("turn_order_built", initiative_queue)

func _run_round() -> void:
	print("[CombatMgr] === ROUND %d START ===" % current_round)
	emit_signal("round_started", current_round)
	
	if tm:
		# Use TurnManager for proper turn handling with status blocking
		tm.build_initiative(initiative_queue)
		var current_actor = tm.next_turn()
		
		while current_actor != null:
			if current_actor.has_method("take_turn"):
				emit_signal("turn_started", current_actor)
				current_actor.take_turn(self)
				emit_signal("turn_ended", current_actor)
			
			# Check for victory after each action
			if _check_victory():
				print("[CombatMgr] Victory condition met during round %d" % current_round)
				return
				
	else:
		# Fallback to simple iteration if no TurnManager
		for unit in initiative_queue:
			if unit.has_method("take_turn"):
				emit_signal("turn_started", unit)
				unit.take_turn(self)
				emit_signal("turn_ended", unit)
			
			# Check for victory after each action
			if _check_victory():
				print("[CombatMgr] Victory condition met during round %d" % current_round)
				return
			if _check_victory():
				print("[CombatMgr] Victory condition met during round %d" % current_round)
				return
	
	print("[CombatMgr] === ROUND %d END ===" % current_round)

func get_enemies(unit: Node) -> Array:
	var enemies = []
	for u in initiative_queue:
		# Only consider living enemies
		var u_team = u.get_team() if u.has_method("get_team") else "friends"
		var unit_team = unit.get_team() if unit.has_method("get_team") else "friends"
		if u_team != unit_team and (not u.has_method("is_dead") or not u.is_dead()):
			enemies.append(u)
	return enemies

func damage(attacker: Node, target: Node, amount: int, _type: String = "Physical") -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(amount)
		print("[CombatMgr] %s takes %d damage (HP: %d)" % [target.name, amount, target.hp])
		# Emit damage_dealt signal for combat log
		emit_signal("damage_dealt", attacker, target, amount, _type)

func _check_victory() -> bool:
	var friends_alive: Array = []
	var foes_alive: Array = []
	
	for u in initiative_queue:
		# Check if unit is alive (hp > 0)
		if "hp" in u and u.hp > 0:
			if u.get_team() == "friends":
				friends_alive.append(u)
			elif u.get_team() == "foes":
				foes_alive.append(u)
	
	# Battle ends if either side has no living units
	return foes_alive.size() == 0 or friends_alive.size() == 0

func use_ability(actor: Node, ability_name: String) -> void:
	"""Handle ability usage with auto-targeting"""
	if not actor:
		push_warning("[BattleManager] use_ability called with null actor")
		return
	
	print("[BattleManager] %s uses ability: %s" % [actor.name, ability_name])
	
	# Get ability from registry
	var ability_reg = get_node_or_null("/root/AbilityReg")
	if not ability_reg:
		push_warning("[BattleManager] AbilityReg not found")
		return
	
	var ability = ability_reg.get_ability(ability_name)
	if not ability:
		push_warning("[BattleManager] Ability not found: %s" % ability_name)
		return
	
	# Determine target based on ability type
	var target: Node = null
	
	# Check if ability has buff_to_apply (self-targeting)
	if ability.has_method("get") and ability.get("buff_to_apply"):
		target = actor
		print("[BattleManager] Self-targeting ability: %s" % ability_name)
	else:
		# Auto-target first valid enemy
		var enemies = get_enemies(actor)
		if enemies.size() > 0:
			target = enemies[0]
			print("[BattleManager] Auto-targeting enemy: %s" % target.name)
		else:
			print("[BattleManager] No valid targets for ability: %s" % ability_name)
			return
	
	# Apply ability effect
	_apply_ability_effect(actor, target, ability)

func _apply_ability_effect(actor: Node, target: Node, ability: Resource) -> void:
	"""Apply the actual ability effect"""
	if not ability.has_method("get"):
		push_warning("[BattleManager] Invalid ability resource")
		return
	
	var ability_name = ability.get("resource_name") or "Unknown"
	
	# Handle buff abilities
	if ability.get("buff_to_apply"):
		var buff_name = ability.get("buff_to_apply")
		var buff_reg = get_node_or_null("/root/BuffReg")
		if buff_reg and buff_reg.has_method("apply_buff"):
			buff_reg.apply_buff(target, buff_name, 1, 5)  # 1 stack, 5 duration
			print("[BattleManager] Applied buff %s to %s" % [buff_name, target.name])
		else:
			push_warning("[BattleManager] BuffReg not available for buff: %s" % buff_name)
	
	# Handle direct damage abilities (future expansion)
	var damage_amount = ability.get("damage") or 0
	if damage_amount > 0:
		# Pass actor as attacker so CombatLog shows correct name
		damage(actor, target, damage_amount, ability.get("damage_type") or "Physical")
	
	# Log the ability usage for combat log
	print("[BattleManager] %s used %s on %s" % [actor.name, ability_name, target.name])
#EOF
