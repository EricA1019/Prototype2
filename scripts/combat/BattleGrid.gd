# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BattleGrid.gd                                                           ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ 6x6 tactical grid system for turn-based combat. Supports positioning   ║
# ║ entities on a grid with team-based side restrictions and large entity   ║
# ║ (2x2) placement. Features clear grid visualization and collision        ║
# ║ detection.                                                               ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑29                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends Node2D
class_name BattleGrid

signal tile_clicked(grid_position: Vector2i)
signal entity_moved(entity: Node, from: Vector2i, to: Vector2i)

# Grid configuration
const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 6
const TILE_SIZE: Vector2 = Vector2(80, 80)
const GRID_LINE_WIDTH: float = 3.0
const GRID_LINE_COLOR: Color = Color.BLACK

# Team areas (allies on left 3 columns, enemies on right 3 columns)
const ALLY_COLUMNS: Array[int] = [0, 1, 2]
const ENEMY_COLUMNS: Array[int] = [3, 4, 5]

# Colors for team areas
const ALLY_TILE_COLOR: Color = Color(0.4, 0.8, 0.4, 0.3)    # Light green
const ENEMY_TILE_COLOR: Color = Color(0.8, 0.4, 0.4, 0.3)   # Light red
const NEUTRAL_TILE_COLOR: Color = Color(0.7, 0.7, 0.7, 0.2) # Light gray

# Grid state
var occupied_tiles: Dictionary = {}  # Vector2i -> Node (entity)
var large_entities: Dictionary = {}  # Node -> Array[Vector2i] (tiles occupied)

func _ready() -> void:
	print("[BattleGrid] Initializing 6x6 battlefield grid")
	_setup_grid()

func _setup_grid() -> void:
	"""Initialize the grid visual representation"""
	# Position grid in center of screen
	var screen_center = get_viewport().get_visible_rect().size / 2
	var grid_pixel_size = Vector2(GRID_WIDTH * TILE_SIZE.x, GRID_HEIGHT * TILE_SIZE.y)
	position = screen_center - grid_pixel_size / 2
	
	print("[BattleGrid] Grid positioned at: %s" % position)
	print("[BattleGrid] Grid size: %dx%d tiles (%s pixels)" % [GRID_WIDTH, GRID_HEIGHT, grid_pixel_size])

func _draw() -> void:
	"""Draw the grid lines and team areas"""
	# Draw team area backgrounds
	_draw_team_areas()
	
	# Draw grid lines
	_draw_grid_lines()
	
	# Draw tile highlights if any
	_draw_tile_highlights()

func _draw_team_areas() -> void:
	"""Draw colored backgrounds for team areas"""
	# Draw ally area (left 3 columns)
	var ally_rect = Rect2(
		Vector2(0, 0),
		Vector2(3 * TILE_SIZE.x, GRID_HEIGHT * TILE_SIZE.y)
	)
	draw_rect(ally_rect, ALLY_TILE_COLOR)
	
	# Draw enemy area (right 3 columns)
	var enemy_rect = Rect2(
		Vector2(3 * TILE_SIZE.x, 0),
		Vector2(3 * TILE_SIZE.x, GRID_HEIGHT * TILE_SIZE.y)
	)
	draw_rect(enemy_rect, ENEMY_TILE_COLOR)

func _draw_grid_lines() -> void:
	"""Draw bold grid lines"""
	var grid_pixel_size = Vector2(GRID_WIDTH * TILE_SIZE.x, GRID_HEIGHT * TILE_SIZE.y)
	
	# Vertical lines
	for x in range(GRID_WIDTH + 1):
		var line_x = x * TILE_SIZE.x
		draw_line(
			Vector2(line_x, 0),
			Vector2(line_x, grid_pixel_size.y),
			GRID_LINE_COLOR,
			GRID_LINE_WIDTH
		)
	
	# Horizontal lines
	for y in range(GRID_HEIGHT + 1):
		var line_y = y * TILE_SIZE.y
		draw_line(
			Vector2(0, line_y),
			Vector2(grid_pixel_size.x, line_y),
			GRID_LINE_COLOR,
			GRID_LINE_WIDTH
		)

func _draw_tile_highlights() -> void:
	"""Draw highlights for special tiles (valid moves, targets, etc.)"""
	# This can be extended for movement/targeting visualization
	pass

func _input(event: InputEvent) -> void:
	"""Handle mouse clicks on grid tiles"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = to_local(event.global_position)
		var grid_pos = pixel_to_grid(local_pos)
		
		if is_valid_grid_position(grid_pos):
			emit_signal("tile_clicked", grid_pos)
			print("[BattleGrid] Tile clicked: %s" % grid_pos)

# ═══════════════════════════════════════════════════════════════════════════
# Position Conversion
# ═══════════════════════════════════════════════════════════════════════════

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to pixel position (tile center)"""
	return Vector2(
		grid_pos.x * TILE_SIZE.x + TILE_SIZE.x / 2,
		grid_pos.y * TILE_SIZE.y + TILE_SIZE.y / 2
	)

func pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
	"""Convert pixel position to grid coordinates"""
	return Vector2i(
		int(pixel_pos.x / TILE_SIZE.x),
		int(pixel_pos.y / TILE_SIZE.y)
	)

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	"""Check if grid position is within bounds"""
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT

# ═══════════════════════════════════════════════════════════════════════════
# Entity Placement
# ═══════════════════════════════════════════════════════════════════════════

func place_entity(entity: Node, grid_pos: Vector2i, is_large: bool = false) -> bool:
	"""Place an entity on the grid at specified position"""
	if not is_valid_grid_position(grid_pos):
		print("[BattleGrid] Invalid grid position: %s" % grid_pos)
		return false
	
	var tiles_needed: Array[Vector2i] = []
	
	if is_large:
		# Large entity occupies 2x2 tiles
		tiles_needed = [
			grid_pos,
			Vector2i(grid_pos.x + 1, grid_pos.y),
			Vector2i(grid_pos.x, grid_pos.y + 1),
			Vector2i(grid_pos.x + 1, grid_pos.y + 1)
		]
		
		# Check if all tiles are valid and unoccupied
		for tile in tiles_needed:
			if not is_valid_grid_position(tile) or is_tile_occupied(tile):
				print("[BattleGrid] Cannot place large entity at %s - tiles blocked" % grid_pos)
				return false
	else:
		# Normal entity occupies 1 tile
		tiles_needed = [grid_pos]
		if is_tile_occupied(grid_pos):
			print("[BattleGrid] Tile %s already occupied" % grid_pos)
			return false
	
	# Place entity
	for tile in tiles_needed:
		occupied_tiles[tile] = entity
	
	if is_large:
		large_entities[entity] = tiles_needed
	
	# Position entity visually
	if entity is Node2D:
		var pixel_pos = grid_to_pixel(grid_pos)
		if is_large:
			# Center large entity between its 4 tiles
			pixel_pos += Vector2(TILE_SIZE.x / 2, TILE_SIZE.y / 2)
		(entity as Node2D).global_position = to_global(pixel_pos)
	
	print("[BattleGrid] Placed entity %s at grid %s (tiles: %s)" % [entity.name, grid_pos, tiles_needed])
	return true

func remove_entity(entity: Node) -> void:
	"""Remove an entity from the grid"""
	var tiles_to_clear: Array[Vector2i] = []
	
	# Find all tiles occupied by this entity
	for tile in occupied_tiles:
		if occupied_tiles[tile] == entity:
			tiles_to_clear.append(tile)
	
	# Clear the tiles
	for tile in tiles_to_clear:
		occupied_tiles.erase(tile)
	
	# Remove from large entities if applicable
	if entity in large_entities:
		large_entities.erase(entity)
	
	print("[BattleGrid] Removed entity %s from grid" % entity.name)

func move_entity(entity: Node, new_grid_pos: Vector2i) -> bool:
	"""Move an entity to a new grid position"""
	if not is_entity_on_grid(entity):
		print("[BattleGrid] Entity %s not found on grid" % entity.name)
		return false
	
	var is_large = entity in large_entities
	var old_pos = get_entity_grid_position(entity)
	
	# Remove from current position
	remove_entity(entity)
	
	# Try to place at new position
	if place_entity(entity, new_grid_pos, is_large):
		emit_signal("entity_moved", entity, old_pos, new_grid_pos)
		return true
	else:
		# Restore to old position if new placement failed
		place_entity(entity, old_pos, is_large)
		return false

func is_tile_occupied(grid_pos: Vector2i) -> bool:
	"""Check if a specific tile is occupied"""
	return grid_pos in occupied_tiles

func is_entity_on_grid(entity: Node) -> bool:
	"""Check if an entity is placed on the grid"""
	return entity in occupied_tiles.values() or entity in large_entities

func get_entity_grid_position(entity: Node) -> Vector2i:
	"""Get the grid position of an entity (top-left for large entities)"""
	for tile in occupied_tiles:
		if occupied_tiles[tile] == entity:
			return tile
	return Vector2i(-1, -1)  # Not found

func get_entity_at_position(grid_pos: Vector2i) -> Node:
	"""Get the entity at a specific grid position"""
	return occupied_tiles.get(grid_pos, null)

# ═══════════════════════════════════════════════════════════════════════════
# Team Restrictions
# ═══════════════════════════════════════════════════════════════════════════

func is_valid_position_for_team(grid_pos: Vector2i, team: String) -> bool:
	"""Check if a grid position is valid for a specific team"""
	if not is_valid_grid_position(grid_pos):
		return false
	
	match team.to_lower():
		"friends", "allies":
			return grid_pos.x in ALLY_COLUMNS
		"foes", "enemies":
			return grid_pos.x in ENEMY_COLUMNS
		_:
			# Unknown team - allow anywhere for flexibility
			return true

func get_valid_positions_for_team(team: String, is_large: bool = false) -> Array[Vector2i]:
	"""Get all valid grid positions for a team"""
	var valid_positions: Array[Vector2i] = []
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var pos = Vector2i(x, y)
			if is_valid_position_for_team(pos, team):
				if is_large:
					# For large entities, check if 2x2 area fits
					var can_place_large = true
					for dx in range(2):
						for dy in range(2):
							var check_pos = Vector2i(x + dx, y + dy)
							if not is_valid_position_for_team(check_pos, team) or is_tile_occupied(check_pos):
								can_place_large = false
								break
						if not can_place_large:
							break
					if can_place_large:
						valid_positions.append(pos)
				else:
					if not is_tile_occupied(pos):
						valid_positions.append(pos)
	
	return valid_positions

# ═══════════════════════════════════════════════════════════════════════════
# Utility Functions
# ═══════════════════════════════════════════════════════════════════════════

func get_spawn_position_for_team(team: String, entity_index: int = 0, is_large: bool = false) -> Vector2i:
	"""Get a default spawn position for a team member"""
	var valid_positions = get_valid_positions_for_team(team, is_large)
	
	if valid_positions.is_empty():
		print("[BattleGrid] No valid positions for team %s" % team)
		return Vector2i(-1, -1)
	
	# Use modulo to cycle through positions if we have more entities than positions
	var index = entity_index % valid_positions.size()
	return valid_positions[index]

func clear_grid() -> void:
	"""Clear all entities from the grid"""
	occupied_tiles.clear()
	large_entities.clear()
	queue_redraw()
	print("[BattleGrid] Grid cleared")

func get_grid_info() -> Dictionary:
	"""Get current grid state information"""
	return {
		"size": Vector2i(GRID_WIDTH, GRID_HEIGHT),
		"tile_size": TILE_SIZE,
		"occupied_tiles": occupied_tiles.size(),
		"large_entities": large_entities.size(),
		"ally_columns": ALLY_COLUMNS,
		"enemy_columns": ENEMY_COLUMNS
	}

#EOF
