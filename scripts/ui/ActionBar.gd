# scripts/ui/ActionBar.gd
extends Panel
class_name ActionBar

@onready var button_container: Node = $VBox/ButtonContainer

var current_entity: Node = null

signal ability_used(entity: Node, ability_name: String)

func _ready() -> void:
	print("[UI][ActionBar] Ready")
	# Start hidden until an entity's turn
	visible = false

func show_for(entity: Node) -> void:
	if not entity:
		push_warning("[UI][ActionBar] show_for called with null entity")
		return
	
	current_entity = entity
	print("[UI][ActionBar] show_for: %s" % entity.name)
	
	# Clear existing buttons
	clear()
	
	# Get entity's abilities
	var abilities: Array = []
	if entity.has_method("get_abilities"):
		abilities = entity.get_abilities()
		print("[UI][ActionBar] Found abilities via get_abilities(): %s" % str(abilities))
	elif entity.has_method("get") and entity.get("abilities") != null:
		abilities = entity.get("abilities")
		print("[UI][ActionBar] Found abilities via get(): %s" % str(abilities))
	elif "abilities" in entity:
		abilities = entity.abilities
		print("[UI][ActionBar] Found abilities via direct property: %s" % str(abilities))
	else:
		print("[UI][ActionBar] No abilities found for entity: %s" % entity.name)
		abilities = []
	
	# Create buttons for each ability
	for ability_name in abilities:
		_create_ability_button(ability_name)
	
	# Show the action bar
	visible = true
	print("[UI][ActionBar] ActionBar now visible with %d buttons" % get_ability_count())

func clear() -> void:
	print("[UI][ActionBar] clear")
	# Remove all ability buttons immediately
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()
	
	current_entity = null
	visible = false

func _create_ability_button(ability_name: String) -> void:
	var button = Button.new()
	button.text = ability_name
	button.custom_minimum_size = Vector2(80, 40)
	
	# Connect button press to handler
	button.pressed.connect(_on_ability_button_pressed.bind(ability_name))
	
	# Add to container
	button_container.add_child(button)
	
	print("[UI][ActionBar] Created button for ability: %s" % ability_name)

func _on_ability_button_pressed(ability_name: String) -> void:
	if not current_entity:
		push_warning("[UI][ActionBar] Button pressed but no current entity")
		return
	
	print("[UI][ActionBar] Ability button pressed: %s" % ability_name)
	
	# Emit signal for BattleManager to handle
	emit_signal("ability_used", current_entity, ability_name)

func hide_actions() -> void:
	"""Hide the action bar (called when turn ends)"""
	visible = false

func get_current_entity() -> Node:
	return current_entity

func get_ability_count() -> int:
	"""Get number of ability buttons currently displayed"""
	return button_container.get_child_count()
