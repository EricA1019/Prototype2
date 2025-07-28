# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_AbilityRegistry.gd                                                 ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit‑tests for the **AbilityRegistry** autoload.  Relies solely on the ║
# ║ public API — no direct access to private members.                       ║
# ║                                                                        ║
# ║ Run via GUT (Ctrl + Shift + B or `gut_cli.gd`).                         ║
# ║ Author  : Eric Acosta                                                  ║
# ║ Updated : 2025‑07‑25                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

# ─── Helpers ────────────────────────────────────────────────────────────────
func _ability_reg() -> Node:
	var reg := get_node_or_null("/root/AbilityReg")
	assert_not_null(reg, "AbilityReg autoload missing – check Project ▶ AutoLoad")
	return reg

func before_each():
	# Ensure the registry is bootstrapped before each test
	var reg = _ability_reg()
	if reg.list_names().size() == 0:
		reg._bootstrap()

func after_each():
	# Clean up ability registry after each test to prevent resource leaks
	var reg = _ability_reg()
	if reg != null and reg.has_method("_cleanup"):
		reg._cleanup()

# ─── Tests ─────────────────────────────────────────────────────────────────
func test_ability_resource_class_exists() -> void:
	# Test that we can create an AbilityResource directly
	var ability_res = AbilityResource.new()
	assert_not_null(ability_res, "Could not create AbilityResource instance")
	assert_true(ability_res is Resource, "AbilityResource should extend Resource")
	assert_true(ability_res is AbilityResource, "Type check failed")

func test_load_individual_ability_file() -> void:
	# Test loading a specific ability file directly
	var res = load("res://data/abilities/bleed.tres")
	assert_not_null(res, "Could not load bleed.tres")
	assert_true(res is AbilityResource, "Loaded resource is not an AbilityResource")
	assert_eq(res.display_name, "Bleed", "Incorrect display name")
	assert_eq(res.damage_type, "Physical", "Incorrect damage type")

func test_registry_has_entries() -> void:
	var reg = _ability_reg()
	## Ensure at least one ability is loaded (script generator writes 4).
	assert_gt(reg.list_names().size(), 0, "AbilityRegistry loaded zero abilities – populate data/abilities/")

func test_get_ability_returns_resource() -> void:
	var reg = _ability_reg()
	for ability_name in reg.list_names():
		var res = reg.get_ability(ability_name)
		assert_not_null(res, "get_ability(%s) returned null" % ability_name)
		assert_eq(res.display_name, ability_name, "Resource name/display mismatch for %s" % ability_name)

func test_filter_by_damage_type() -> void:
	var reg = _ability_reg()
	var physical_only: Array = reg.filter_by_damage_type("Physical")
	for ab in physical_only:
		assert_eq(ab.damage_type, "Physical")

func test_filter_by_tags() -> void:
	var reg = _ability_reg()
	var required_tags: Array[String] = ["DOT"]
	var dot_abilities: Array = reg.filter_by_tags(required_tags)
	for ab in dot_abilities:
		assert_true("DOT" in ab.tags, "%s missing DOT tag" % ab.display_name)
#EOF
