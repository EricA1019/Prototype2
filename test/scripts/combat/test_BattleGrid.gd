# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ test_BattleGrid.gd                                                      ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Unit tests for the BattleGrid system. Tests grid functionality,         ║
# ║ entity placement, team restrictions, and large entity support.          ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑29                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends "res://addons/gut/test.gd"

const BattleGridScene = preload("res://scenes/battle/BattleGrid.tscn")

var battle_grid: Node

func before_each():
	battle_grid = BattleGridScene.instantiate()
	add_child_autoqfree(battle_grid)
	await get_tree().process_frame

func test_grid_initialization():
	"""Test that the grid initializes with correct dimensions"""
	assert_not_null(battle_grid, "BattleGrid should instantiate successfully")
	
	var grid_info = battle_grid.get_grid_info()
	assert_eq(grid_info.size.x, 6, "Grid should be 6 tiles wide")
	assert_eq(grid_info.size.y, 6, "Grid should be 6 tiles high")
	assert_eq(grid_info.ally_columns, [0, 1, 2], "Ally columns should be 0-2")
	assert_eq(grid_info.enemy_columns, [3, 4, 5], "Enemy columns should be 3-5")

func test_position_conversion():
	"""Test grid-to-pixel and pixel-to-grid conversion"""
	var grid_pos = Vector2i(2, 3)
	var pixel_pos = battle_grid.grid_to_pixel(grid_pos)
	var back_to_grid = battle_grid.pixel_to_grid(pixel_pos)
	
	assert_eq(back_to_grid, grid_pos, "Position conversion should be reversible")

func test_valid_grid_positions():
	"""Test grid boundary validation"""
	assert_true(battle_grid.is_valid_grid_position(Vector2i(0, 0)), "Top-left should be valid")
	assert_true(battle_grid.is_valid_grid_position(Vector2i(5, 5)), "Bottom-right should be valid")
	assert_false(battle_grid.is_valid_grid_position(Vector2i(-1, 0)), "Negative X should be invalid")
	assert_false(battle_grid.is_valid_grid_position(Vector2i(0, -1)), "Negative Y should be invalid")
	assert_false(battle_grid.is_valid_grid_position(Vector2i(6, 0)), "X=6 should be invalid")
	assert_false(battle_grid.is_valid_grid_position(Vector2i(0, 6)), "Y=6 should be invalid")

func test_entity_placement():
	"""Test placing normal entities on the grid"""
	var mock_entity = Node2D.new()
	mock_entity.name = "TestEntity"
	add_child_autoqfree(mock_entity)
	
	var grid_pos = Vector2i(1, 1)
	var success = battle_grid.place_entity(mock_entity, grid_pos, false)
	
	assert_true(success, "Entity placement should succeed")
	assert_true(battle_grid.is_tile_occupied(grid_pos), "Tile should be marked as occupied")
	assert_eq(battle_grid.get_entity_at_position(grid_pos), mock_entity, "Should find entity at position")
	assert_true(battle_grid.is_entity_on_grid(mock_entity), "Entity should be marked as on grid")

func test_large_entity_placement():
	"""Test placing large (2x2) entities on the grid"""
	var large_entity = Node2D.new()
	large_entity.name = "LargeEntity"
	add_child_autoqfree(large_entity)
	
	var grid_pos = Vector2i(1, 1)
	var success = battle_grid.place_entity(large_entity, grid_pos, true)
	
	assert_true(success, "Large entity placement should succeed")
	
	# Check all 4 tiles are occupied
	var expected_tiles = [
		Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(1, 2), Vector2i(2, 2)
	]
	
	for tile in expected_tiles:
		assert_true(battle_grid.is_tile_occupied(tile), "All 2x2 tiles should be occupied: %s" % tile)
		assert_eq(battle_grid.get_entity_at_position(tile), large_entity, "All tiles should reference the large entity")

func test_collision_detection():
	"""Test that entities cannot be placed on occupied tiles"""
	var entity1 = Node2D.new()
	entity1.name = "Entity1"
	add_child_autoqfree(entity1)
	
	var entity2 = Node2D.new()
	entity2.name = "Entity2"
	add_child_autoqfree(entity2)
	
	var grid_pos = Vector2i(2, 2)
	
	# Place first entity
	var success1 = battle_grid.place_entity(entity1, grid_pos, false)
	assert_true(success1, "First entity should place successfully")
	
	# Try to place second entity on same tile
	var success2 = battle_grid.place_entity(entity2, grid_pos, false)
	assert_false(success2, "Second entity should not be able to occupy same tile")

func test_team_restrictions():
	"""Test team-based position validation"""
	# Test ally positions
	assert_true(battle_grid.is_valid_position_for_team(Vector2i(0, 0), "friends"), "Allies should use left columns")
	assert_true(battle_grid.is_valid_position_for_team(Vector2i(2, 3), "allies"), "Allies should use left columns")
	assert_false(battle_grid.is_valid_position_for_team(Vector2i(3, 0), "friends"), "Allies should not use right columns")
	
	# Test enemy positions
	assert_true(battle_grid.is_valid_position_for_team(Vector2i(3, 0), "foes"), "Enemies should use right columns")
	assert_true(battle_grid.is_valid_position_for_team(Vector2i(5, 5), "enemies"), "Enemies should use right columns")
	assert_false(battle_grid.is_valid_position_for_team(Vector2i(2, 0), "foes"), "Enemies should not use left columns")

func test_spawn_position_assignment():
	"""Test automatic spawn position assignment for teams"""
	var ally_pos1 = battle_grid.get_spawn_position_for_team("friends", 0)
	var ally_pos2 = battle_grid.get_spawn_position_for_team("friends", 1)
	var enemy_pos1 = battle_grid.get_spawn_position_for_team("foes", 0)
	var enemy_pos2 = battle_grid.get_spawn_position_for_team("foes", 1)
	
	# Verify positions are valid for their teams
	assert_true(battle_grid.is_valid_position_for_team(ally_pos1, "friends"), "Auto ally position should be valid")
	assert_true(battle_grid.is_valid_position_for_team(ally_pos2, "friends"), "Second ally position should be valid")
	assert_true(battle_grid.is_valid_position_for_team(enemy_pos1, "foes"), "Auto enemy position should be valid")
	assert_true(battle_grid.is_valid_position_for_team(enemy_pos2, "foes"), "Second enemy position should be valid")
	
	# Verify positions are different
	assert_ne(ally_pos1, ally_pos2, "Multiple ally positions should be different")
	assert_ne(enemy_pos1, enemy_pos2, "Multiple enemy positions should be different")

func test_entity_movement():
	"""Test moving entities between grid positions"""
	var entity = Node2D.new()
	entity.name = "MovingEntity"
	add_child_autoqfree(entity)
	
	var start_pos = Vector2i(1, 1)
	var end_pos = Vector2i(1, 2)
	
	# Place entity
	battle_grid.place_entity(entity, start_pos, false)
	assert_true(battle_grid.is_tile_occupied(start_pos), "Start position should be occupied")
	
	# Move entity
	var move_success = battle_grid.move_entity(entity, end_pos)
	assert_true(move_success, "Entity movement should succeed")
	assert_false(battle_grid.is_tile_occupied(start_pos), "Start position should be cleared")
	assert_true(battle_grid.is_tile_occupied(end_pos), "End position should be occupied")
	assert_eq(battle_grid.get_entity_grid_position(entity), end_pos, "Entity should be at new position")

func test_entity_removal():
	"""Test removing entities from the grid"""
	var entity = Node2D.new()
	entity.name = "RemovableEntity"
	add_child_autoqfree(entity)
	
	var grid_pos = Vector2i(2, 2)
	battle_grid.place_entity(entity, grid_pos, false)
	
	# Remove entity
	battle_grid.remove_entity(entity)
	assert_false(battle_grid.is_tile_occupied(grid_pos), "Tile should be cleared after removal")
	assert_false(battle_grid.is_entity_on_grid(entity), "Entity should no longer be on grid")
	assert_eq(battle_grid.get_entity_grid_position(entity), Vector2i(-1, -1), "Entity position should be invalid")

func test_grid_clear():
	"""Test clearing all entities from the grid"""
	var entity1 = Node2D.new()
	entity1.name = "Entity1"
	add_child_autoqfree(entity1)
	
	var entity2 = Node2D.new()
	entity2.name = "Entity2"
	add_child_autoqfree(entity2)
	
	battle_grid.place_entity(entity1, Vector2i(0, 0), false)
	battle_grid.place_entity(entity2, Vector2i(5, 5), false)
	
	# Clear grid
	battle_grid.clear_grid()
	
	var grid_info = battle_grid.get_grid_info()
	assert_eq(grid_info.occupied_tiles, 0, "No tiles should be occupied after clear")
	assert_eq(grid_info.large_entities, 0, "No large entities should remain after clear")

func test_large_entity_boundary_check():
	"""Test that large entities cannot be placed near grid edges"""
	var large_entity = Node2D.new()
	large_entity.name = "EdgeLargeEntity"
	add_child_autoqfree(large_entity)
	
	# Try to place at bottom-right corner (should fail - would go outside grid)
	var success = battle_grid.place_entity(large_entity, Vector2i(5, 5), true)
	assert_false(success, "Large entity should not fit at grid edge")
	
	# Try to place at valid position for large entity
	var valid_success = battle_grid.place_entity(large_entity, Vector2i(4, 4), true)
	assert_true(valid_success, "Large entity should fit at position (4,4)")

#EOF
