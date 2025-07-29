# InitiativeBar.gd
extends Control
class_name InitiativeBar

signal populated(count:int)
signal highlighted(actor:Node)

@export var fallback_icon: Texture2D
@export var dead_alpha: float = 0.5
@export var current_outline_thickness: int = 2

var _bm: Node
var _buttons: Array = []            # Array[TextureButton]
var _id_by_btn: Dictionary = {}     # btn -> id
var _btn_by_id: Dictionary = {}     # id  -> btn (only the last one for each ID)
var _using_missing: Dictionary = {} # id  -> bool
var _btn_tooltips: Dictionary = {}  # btn -> base_tooltip (without death status)

func bind(bm: Node) -> void:
	_bm = bm
	if not bm.has_signal("turn_order_built"):
		push_warning("[UI][InitBar] BattleManager lacks turn_order_built signal")
	# Connect to existing BattleManager signals only
	if bm.has_signal("turn_order_built"):
		bm.turn_order_built.connect(_on_turn_order_built)
	else:
		push_warning("[UI][InitBar] BattleManager lacks turn_order_built signal")
	if bm.has_signal("turn_started"):
		bm.turn_started.connect(_on_turn_started)
	if bm.has_signal("turn_ended"):
		bm.turn_ended.connect(_on_turn_ended)
	
	# Ensure proper container constraints
	custom_minimum_size = Vector2(0, 56)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	print("[UI][InitBar] bound to BattleManager")

#// Public helpers for tests (avoid peeking privates)
func get_order_ids() -> Array:
	var out: Array = []
	for btn in _buttons:
		out.append(_id_by_btn.get(btn, -1))
	return out

func is_slot_dead(id:int) -> bool:
	var ent := instance_from_id(id)
	return ent == null or (("hp" in ent) and int(ent.hp) <= 0)

# ─── Population ─────────────────────────────────────────────────────────────


func _on_turn_order_built(units:Array) -> void:
	print("[UI][InitBar] populate ", units.size())
	populate(units)

func populate(units:Array) -> void:
	_clear()
	_buttons.clear()
	_id_by_btn.clear()
	_btn_by_id.clear()
	_using_missing.clear()
	_btn_tooltips.clear()
	
	# Generate the next 10 turns in sequence
	var turn_sequence := _generate_turn_sequence(units, 10)
	
	for i in range(turn_sequence.size()):
		var u = turn_sequence[i]
		if u == null: continue
		var tex := _resolve_portrait(u)
		var btn := TextureButton.new()
		btn.texture_normal = tex
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(56, 56)  # Fixed size for portraits
		btn.size_flags_horizontal = 0  # prevent stretching beyond min size
		btn.size_flags_vertical = 0
		var base_tooltip = _tooltip_for(u) + " (Turn %d)" % (i + 1)
		btn.tooltip_text = base_tooltip
		_btn_tooltips[btn] = base_tooltip  # Store the base tooltip
		btn.pressed.connect(_on_portrait_pressed.bind(u))
		_buttons.append(btn)
		add_child(btn)
		var id: int = u.get_instance_id()
		_id_by_btn[btn] = id
		_btn_by_id[id] = btn  # Note: this will only store the last button for each unit
		_using_missing[id] = _is_missing_portrait(u)
		# subscribe to hp signals with modern syntax (only once per unique unit)
		if not u.hp_changed.is_connected(_on_hp_changed.bind(id)):
			if u.has_signal("hp_changed"):
				u.hp_changed.connect(_on_hp_changed.bind(id))
		if not u.died.is_connected(_on_entity_died.bind(id)):
			if u.has_signal("died"):
				u.died.connect(_on_entity_died.bind(id))
	_update_dead_states(units)
	emit_signal("populated", _buttons.size())

# Generate the next N turns in initiative order
func _generate_turn_sequence(units: Array, count: int) -> Array:
	if units.is_empty():
		return []
	
	# Sort units by speed (highest first) to get base initiative order
	var sorted_units = units.duplicate()
	sorted_units.sort_custom(func(a, b): return a.speed > b.speed)
	
	var sequence: Array = []
	var turn_index: int = 0
	
	# Generate the sequence by cycling through units in initiative order
	for i in range(count):
		var unit = sorted_units[turn_index % sorted_units.size()]
		sequence.append(unit)
		turn_index += 1
	
	return sequence

func _clear() -> void:
	for c in get_children():
		c.queue_free()

# ─── Highlighting ──────────────────────────────────────────────────────────
func _on_turn_started(actor:Node) -> void:
	_highlight(actor)

func _on_turn_ended(_actor:Node) -> void:
	# keep highlight until next actor
	pass

func _highlight(actor:Node) -> void:
	var id: int = actor.get_instance_id()
	for btn in _buttons:
		var is_current: bool = _id_by_btn.get(btn, -1) == id
		btn.modulate = Color.WHITE
		btn.self_modulate = Color.WHITE
		if is_current:
			btn.add_theme_stylebox_override("focus", _outline_style())
			btn.add_theme_stylebox_override("normal", _outline_style())
		else:
			btn.remove_theme_stylebox_override("focus")
			btn.remove_theme_stylebox_override("normal")
	_update_dead_state_for(id)
	emit_signal("highlighted", actor)
	print("[UI][InitBar] highlight id=", id)

func _outline_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.border_width_all = current_outline_thickness
	sb.border_color = Color(1, 1, 0, 1)
	sb.draw_center = false
	return sb

# ─── HP / Death updates ────────────────────────────────────────────────────
func _on_hp_changed(_current:int, _max_hp:int, id:int) -> void:
	_update_dead_state_for(id)

func _on_entity_died(id:int) -> void:
	_update_dead_state_for(id)

func _update_dead_states(units:Array) -> void:
	for u in units:
		if u == null: continue
		_update_dead_state_for(u.get_instance_id())

func _update_dead_state_for(id:int) -> void:
	var ent := instance_from_id(id)
	var is_dead: bool = ent == null or (("hp" in ent) and int(ent.hp) <= 0)
	var use_missing: bool = _using_missing.get(id, false)
	
	# Update ALL buttons for this entity ID, not just the last one
	for btn in _buttons:
		if _id_by_btn.get(btn, -1) == id:
			var base_tooltip = _btn_tooltips.get(btn, _tooltip_for(ent))
			if is_dead:
				if use_missing:
					btn.modulate = Color(1,1,1,1)
				else:
					btn.modulate = Color(1,1,1,dead_alpha)
				btn.tooltip_text = base_tooltip + " — DEAD"
			else:
				btn.modulate = Color(1,1,1,1)
				btn.tooltip_text = base_tooltip

# ─── Interaction ───────────────────────────────────────────────────────────
func _on_portrait_pressed(entity:Node) -> void:
	print("[UI][InitBar] click ", entity)
	_focus_camera_on(entity)

func _focus_camera_on(entity:Node) -> void:
	var cam:Camera2D = null
	var cams := get_tree().get_nodes_in_group("Camera")
	if cams.size() > 0:
		cam = cams[0]
	if cam == null:
		cam = get_tree().get_first_node_in_group("Camera2D")
	if cam == null:
		cam = get_tree().get_root().find_child("Camera2D", true, false)
	if cam == null:
		return
	var pos := Vector2.ZERO
	var spr:Node = entity.get_node_or_null("Sprite2D")
	if spr and spr is Node2D:
		pos = (spr as Node2D).global_position
	elif entity is Node2D:
		pos = (entity as Node2D).global_position
	cam.position = pos

# ─── Helpers ───────────────────────────────────────────────────────────────
func _resolve_portrait(u:Node) -> Texture2D:
	var path := ""
	if "data" in u and u.data and u.data.portrait_path != "":
		path = u.data.portrait_path
	var tex:Texture2D = null
	if path != "":
		# Add error handling for texture loading
		if ResourceLoader.exists(path):
			tex = load(path)
		else:
			push_warning("[UI][InitBar] Portrait not found: " + path)
	if tex == null:
		tex = fallback_icon
	return tex

func _is_missing_portrait(u:Node) -> bool:
	if "data" in u and u.data and u.data.portrait_path != "":
		return u.data.portrait_path.findn("missing_asset.png") != -1
	return false

func _tooltip_for(u:Node) -> String:
	if u == null: return "Unknown"
	var entity_name: String = u.data.display_name if ("data" in u and u.data and u.data.display_name) else u.name
	var spd: int = int(u.speed) if ("speed" in u) else 0
	return "%s — SPD %d" % [entity_name, spd]
#EOF
