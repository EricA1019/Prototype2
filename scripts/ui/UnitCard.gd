extends Panel
class_name UnitCard
@export var fallback_icon: Texture2D

var portrait: TextureRect
var name_label: Label
var hp_bar: ProgressBar

func _ready() -> void:
	# Find nodes dynamically to handle test scenarios
	# Use call_deferred to ensure scene is fully loaded
	call_deferred("_find_child_nodes")

func _find_child_nodes() -> void:
	# Try direct paths first
	portrait = get_node_or_null("HBox/Portrait")
	name_label = get_node_or_null("HBox/Right/Name")
	hp_bar = get_node_or_null("HBox/Right/HP")
	# Fallback: find by name anywhere
	if not portrait:
		portrait = find_child("Portrait", true, false) as TextureRect
	if not name_label:
		name_label = find_child("Name", true, false) as Label
	if not hp_bar:
		hp_bar = find_child("HP", true, false) as ProgressBar

func bind(entity: Node) -> void:
	if not entity:
		return
	# Ensure nodes are found (handle deferred setup)
	if not portrait or not name_label or not hp_bar:
		_find_child_nodes()
		if not portrait or not name_label or not hp_bar:
			push_warning("[UnitCard] Missing child nodes - scene may not be properly loaded")
			return
	# Set portrait texture
	if "data" in entity and entity.data:
		# Try portrait_texture first, then fallback to portrait_path
		if "portrait_texture" in entity.data and entity.data.portrait_texture:
			portrait.texture = entity.data.portrait_texture
		elif "portrait_path" in entity.data and entity.data.portrait_path != "":
			portrait.texture = load(entity.data.portrait_path)
		else:
			portrait.texture = fallback_icon
	elif fallback_icon:
		portrait.texture = fallback_icon
	# Set name
	var display_name = ""
	if "data" in entity and entity.data and "display_name" in entity.data and entity.data.display_name:
		display_name = entity.data.display_name
	else:
		display_name = entity.name
	if name_label:
		name_label.text = display_name
	# Initial HP update
	var entity_hp = 0
	var entity_hp_max = 0
	if "hp" in entity:
		entity_hp = int(entity.hp)
	if "data" in entity and entity.data and "stat_block" in entity.data and entity.data.stat_block:
		entity_hp_max = int(entity.data.stat_block.hp_max)
	elif "hp_max" in entity:
		entity_hp_max = int(entity.hp_max)
	else:
		entity_hp_max = entity_hp if entity_hp > 0 else 100
	
	update_hp(entity_hp, entity_hp_max)
	# Connect HP signals
	if entity.has_signal("hp_changed"):
		entity.hp_changed.connect(_on_hp_changed)
	if entity.has_signal("died"):
		entity.died.connect(_on_entity_died)
	print("[UI][UnitCard] bind", entity)

func _on_hp_changed(current: int, max_hp: int) -> void:
	update_hp(current, max_hp)

func _on_entity_died() -> void:
	if hp_bar:
		update_hp(0, int(hp_bar.max_value))

func update_hp(current: int, max_hp: int) -> void:
	if not hp_bar:
		return
	hp_bar.max_value = max_hp
	hp_bar.value = current
	print("[UI][UnitCard] update_hp", current, "/", max_hp)

func show_turn(entity: Node) -> void:
	# Show this card only when it's this entity's turn
	if not entity:
		visible = false
		return
	
	var entity_name = ""
	if "data" in entity and entity.data and "display_name" in entity.data and entity.data.display_name:
		entity_name = entity.data.display_name
	else:
		entity_name = entity.name
	
	visible = (name_label and name_label.text == entity_name)
	print("[UI][UnitCard] show_turn", entity)
