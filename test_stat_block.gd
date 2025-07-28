# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_stat_block.gd                                                      ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for the StatBlockResource class. Tests basic stat            ║
# ║ properties, initialization, and string representation.                  ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

func test_stat_block_creation() -> void:
	var sb := StatBlockResource.new()
	assert_not_null(sb, "Could not create StatBlockResource")
	assert_true(sb is Resource, "StatBlockResource should extend Resource")
	assert_true(sb is StatBlockResource, "Type check failed")

func test_default_values() -> void:
	var sb := StatBlockResource.new()
	assert_eq(sb.hp_max, 30, "Default hp_max should be 30")
	assert_eq(sb.speed, 10, "Default speed should be 10")
	assert_eq(sb.attack, 6, "Default attack should be 6")
	assert_eq(sb.defense, 2, "Default defense should be 2")

func test_setting_custom_values() -> void:
	var sb := StatBlockResource.new()
	sb.hp_max = 50
	sb.speed = 15
	sb.attack = 8
	sb.defense = 4
	
	assert_eq(sb.hp_max, 50, "hp_max should be set to 50")
	assert_eq(sb.speed, 15, "speed should be set to 15")
	assert_eq(sb.attack, 8, "attack should be set to 8")
	assert_eq(sb.defense, 4, "defense should be set to 4")

func test_to_string_method() -> void:
	var sb := StatBlockResource.new()
	sb.hp_max = 25
	sb.speed = 12
	sb.attack = 7
	sb.defense = 3
	
	var expected := "[HP 25 | SPD 12 | ATK 7 | DEF 3]"
	assert_eq(sb._to_string(), expected, "String representation should match expected format")

func test_negative_values() -> void:
	var sb := StatBlockResource.new()
	sb.hp_max = -5
	sb.speed = -2
	sb.attack = -1
	sb.defense = -3
	
	# Even if negative values are set, they should be accessible
	assert_eq(sb.hp_max, -5, "Negative hp_max should be stored")
	assert_eq(sb.speed, -2, "Negative speed should be stored")
	assert_eq(sb.attack, -1, "Negative attack should be stored")
	assert_eq(sb.defense, -3, "Negative defense should be stored")

func test_zero_values() -> void:
	var sb := StatBlockResource.new()
	sb.hp_max = 0
	sb.speed = 0
	sb.attack = 0
	sb.defense = 0
	
	assert_eq(sb.hp_max, 0, "Zero hp_max should be stored")
	assert_eq(sb.speed, 0, "Zero speed should be stored")
	assert_eq(sb.attack, 0, "Zero attack should be stored")
	assert_eq(sb.defense, 0, "Zero defense should be stored")

func test_large_values() -> void:
	var sb := StatBlockResource.new()
	sb.hp_max = 9999
	sb.speed = 999
	sb.attack = 999
	sb.defense = 999
	
	assert_eq(sb.hp_max, 9999, "Large hp_max should be stored")
	assert_eq(sb.speed, 999, "Large speed should be stored")
	assert_eq(sb.attack, 999, "Large attack should be stored")
	assert_eq(sb.defense, 999, "Large defense should be stored")

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
