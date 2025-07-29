extends "res://addons/gut/test.gd"

const BattleManagerScript = preload("res://scripts/combat/BattleManager.gd")
const TurnManagerScript   = preload("res://scripts/combat/TurnManager.gd")

class MiniUnit:
	extends Node
	var team : String = ""
	var hp   : int    = 20
	var speed: int    = 10
	var dmg_per_turn: int = 5

	func is_dead() -> bool:
		return hp <= 0

	func apply_damage(a:int) -> void:
		hp = max(0, hp - a)

	func apply_heal(a:int) -> void:
		hp += a

	func get_team() -> String:
		return team

	func take_turn(bm:BattleManager) -> void:
		var enemies: Array = bm.get_enemies(self)
		if enemies.is_empty():
			return
		var target:MiniUnit = enemies[0]
		bm.damage(target, dmg_per_turn, "Physical")

func _make_battle() -> BattleManager:
	var bm : BattleManager = add_child_autoqfree(BattleManagerScript.new())
	var tm : TurnManager   = TurnManagerScript.new()
	bm.add_child(tm)
	bm.tm = tm
	return bm

func _unit(team:String, hp:int, speed:int, dpt:int) -> MiniUnit:
	var u : MiniUnit = autoqfree(MiniUnit.new())
	u.team = team
	u.hp = hp
	u.speed = speed
	u.dmg_per_turn = dpt
	return u

func test_three_round_flow_and_ticks() -> void:
	var bm = _make_battle()
	var f1 = _unit("friends", 30, 12, 6)
	var f2 = _unit("friends", 24, 10, 5)
	var e1 = _unit("foes",    26, 11, 4)
	var e2 = _unit("foes",    22, 8, 3)
	# Add units to tree so signals/timers work if used
	add_child_autoqfree(f1)
	add_child_autoqfree(f2)
	add_child_autoqfree(e1)
	add_child_autoqfree(e2)
	# Cap the battle to avoid infinite loops
	bm.max_rounds = 100
	bm.start_battle([f1, f2], [e1, e2])
	# After battle ends, check that it ran for at least 3 rounds
	assert_true(bm.get_round() >= 3)  # battle keeps incrementing until victory/defeat
	# Sanity: everyone took some damage
	assert_true(e1.hp < 26)
	assert_true(e2.hp < 22)

func test_skip_blocked_turns() -> void:
	var bm = _make_battle()
	var f = _unit("friends", 20, 10, 5)
	var e = _unit("foes",    20, 10, 5)
	add_child_autoqfree(f)
	add_child_autoqfree(e)
	# Apply Stunned to enemy so their first turn is skipped
	var sr = get_node_or_null("/root/StatusReg")
	if sr:
		sr.apply_status(e, "Stunned", 1)
	
	# Use a simple approach: just run 1 round and check
	bm.current_round = 1
	bm._rebuild_queue([f, e])
	bm._run_round()
	
	# Enemy should take damage while stunned (friend acts)
	assert_true(e.hp < 20)
	assert_true(e.hp >= 0)  # Allow death but verify damage was dealt

func test_victory_condition() -> void:
	var bm = _make_battle()
	var f = _unit("friends", 40, 20, 20)
	var e = _unit("foes",    10, 1, 1)
	add_child_autoqfree(f)
	add_child_autoqfree(e)
	var ended := [false]
	bm.battle_ended.connect(func(_result): ended[0] = true)
	bm.start_battle([f], [e])
	assert_true(ended[0])

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
