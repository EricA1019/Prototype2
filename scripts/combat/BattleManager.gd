# ────────────────────────────────────────────────────────────────────
# BattleManager.gd — Drives rounds & turns for side‑view combat
# ------------------------------------------------------------------
extends Node
class_name BattleManager
signal turn_order_built(units:Array)
signal turn_ended(actor:Node)
signal turn_started(actor:Node)

signal battle_ended(result)

var tm: Node = null   # TurnManager
var current_round: int = 0
var initiative_queue: Array = []
@export var max_rounds: int = 100  # cap at 100 rounds to avoid endless loops (set -1 for no cap)

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

func damage(target: Node, amount: int, _type: String = "Physical") -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(amount)
		print("[CombatMgr] %s takes %d damage (HP: %d)" % [target.name, amount, target.hp])

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
#EOF
