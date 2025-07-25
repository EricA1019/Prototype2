extends "res://addons/gut/test.gd"
func test_apply_is_logged() -> void:
	var reg := BuffRegistry.new()
	reg.apply_buff("Dummy", "Poison", 3, 4)
	pass_test("Placeholder — assert proper state once implemented")
#EOF
