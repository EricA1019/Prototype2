# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_entity_resource.gd                                                 ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for the EntityResource class. Tests basic properties,        ║
# ║ initialization, stat block integration, and string representation.      ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

func test_entity_resource_creation() -> void:
	var er := EntityResource.new()
	assert_not_null(er, "Could not create EntityResource")
	assert_true(er is Resource, "EntityResource should extend Resource")
	assert_true(er is EntityResource, "Type check failed")

func test_default_values() -> void:
	var er := EntityResource.new()
	assert_eq(er.display_name, "New Entity", "Default display_name should be 'New Entity'")
	assert_eq(er.team, "friends", "Default team should be 'friends'")
	assert_eq(er.portrait_path, "res://assets/missing_asset.png", "Default portrait_path incorrect")
	assert_eq(er.sprite_path, "res://assets/missing_asset.png", "Default sprite_path incorrect")
	assert_eq(er.defense_type, "Physical", "Default defense_type should be 'Physical'")
	assert_eq(er.ai_profile, "basic_dps", "Default ai_profile should be 'basic_dps'")

func test_default_collections() -> void:
	var er := EntityResource.new()
	assert_eq(er.abilities.size(), 0, "Default abilities array should be empty")
	assert_eq(er.starting_buffs.size(), 0, "Default starting_buffs array should be empty")
	assert_eq(er.starting_statuses.size(), 0, "Default starting_statuses array should be empty")
	assert_eq(er.resistances.size(), 3, "Default resistances should have 3 entries")

func test_default_resistances() -> void:
	var er := EntityResource.new()
	assert_eq(er.resistances["Physical"], 1.0, "Physical resistance should default to 1.0")
	assert_eq(er.resistances["Infernal"], 1.0, "Infernal resistance should default to 1.0")
	assert_eq(er.resistances["Holy"], 1.0, "Holy resistance should default to 1.0")

func test_setting_custom_values() -> void:
	var er := EntityResource.new()
	er.display_name = "Test Hero"
	er.team = "allies"
	er.defense_type = "Magic"
	er.ai_profile = "tank"
	
	assert_eq(er.display_name, "Test Hero", "display_name should be set to 'Test Hero'")
	assert_eq(er.team, "allies", "team should be set to 'allies'")
	assert_eq(er.defense_type, "Magic", "defense_type should be set to 'Magic'")
	assert_eq(er.ai_profile, "tank", "ai_profile should be set to 'tank'")

func test_stat_block_integration() -> void:
	var er := EntityResource.new()
	var sb := StatBlockResource.new()
	sb.hp_max = 50
	sb.attack = 10
	er.stat_block = sb
	
	assert_not_null(er.stat_block, "stat_block should not be null")
	assert_eq(er.stat_block.hp_max, 50, "stat_block hp_max should be 50")
	assert_eq(er.stat_block.attack, 10, "stat_block attack should be 10")

func test_arrays_manipulation() -> void:
	var er := EntityResource.new()
	er.abilities = ["Slash", "Block"]
	er.starting_buffs = ["Rage"]
	er.starting_statuses = ["Marked", "Stunned"]
	
	assert_eq(er.abilities.size(), 2, "abilities should have 2 entries")
	assert_true("Slash" in er.abilities, "abilities should contain 'Slash'")
	assert_true("Block" in er.abilities, "abilities should contain 'Block'")
	assert_eq(er.starting_buffs.size(), 1, "starting_buffs should have 1 entry")
	assert_true("Rage" in er.starting_buffs, "starting_buffs should contain 'Rage'")
	assert_eq(er.starting_statuses.size(), 2, "starting_statuses should have 2 entries")
	assert_true("Marked" in er.starting_statuses, "starting_statuses should contain 'Marked'")

func test_resistances_manipulation() -> void:
	var er := EntityResource.new()
	er.resistances["Physical"] = 0.5
	er.resistances["Fire"] = 2.0
	
	assert_eq(er.resistances["Physical"], 0.5, "Physical resistance should be 0.5")
	assert_eq(er.resistances["Fire"], 2.0, "Fire resistance should be 2.0")
	assert_eq(er.resistances["Infernal"], 1.0, "Infernal resistance should remain 1.0")

func test_to_string_method() -> void:
	var er := EntityResource.new()
	er.display_name = "Warrior"
	er.team = "heroes"
	
	var expected := "[Warrior | heroes]"
	assert_eq(er._to_string(), expected, "String representation should match expected format")

func test_empty_strings() -> void:
	var er := EntityResource.new()
	er.display_name = ""
	er.team = ""
	er.defense_type = ""
	er.ai_profile = ""
	
	assert_eq(er.display_name, "", "Empty display_name should be stored")
	assert_eq(er.team, "", "Empty team should be stored")
	assert_eq(er.defense_type, "", "Empty defense_type should be stored")
	assert_eq(er.ai_profile, "", "Empty ai_profile should be stored")

func test_asset_paths() -> void:
	var er := EntityResource.new()
	er.portrait_path = "res://assets/portraits/hero.png"
	er.sprite_path = "res://assets/sprites/hero_sprite.png"
	
	assert_eq(er.portrait_path, "res://assets/portraits/hero.png", "portrait_path should be set correctly")
	assert_eq(er.sprite_path, "res://assets/sprites/hero_sprite.png", "sprite_path should be set correctly")

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
