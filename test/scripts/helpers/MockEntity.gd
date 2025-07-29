# test/scripts/helpers/MockEntity.gd
extends Node

var hp: int = 100
var team: String = "friends"

func apply_damage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0

func get_team() -> String:
	return team

func is_dead() -> bool:
	return hp <= 0

func take_turn(_battle_manager: Node) -> void:
	# Mock implementation - do nothing
	pass
