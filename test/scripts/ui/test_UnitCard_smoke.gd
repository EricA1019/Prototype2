extends "res://addons/gut/test.gd"

const UnitCardScene = preload("res://scenes/ui/UnitCard.tscn")

# Simple stub for entity data
class MockData:
	var portrait_path: String = ""
	var display_name: String = "Test"

# Mock entity with hp signals and basic properties
class MockEntity extends Node2D:
	var hp: int = 10
	var hp_max: int = 10
	var data = null

func test_bind_and_update_hp() -> void:
	# Instantiate UnitCard
	var card = UnitCardScene.instantiate()
	assert_true(card.has_method("bind"), "UnitCard should have bind method")
	add_child_autoqfree(card)

	# Create mock entity and bind
	var mock = MockEntity.new()
	mock.hp = 7
	mock.hp_max = 10
	# Attach data stub
	mock.data = MockData.new()
	card.bind(mock)

	# After binding, hp bar should reflect initial hp
	var hp_bar = card.get_node("HPBar") as ProgressBar
	assert_eq(hp_bar.value, 7, "HP bar should match entity hp after bind")

	# Emit hp_changed signal and test update
	mock.hp = 3
	mock.emit_signal("hp_changed", 3, 10)
	assert_eq(hp_bar.value, 3, "HP bar should update after hp_changed signal")
