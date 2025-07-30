# scripts/ui/CombatLog.gd
extends Panel
class_name CombatLog

@onready var rich_text_label: RichTextLabel = $VBox/ScrollContainer/RichTextLabel
@onready var scroll_container: ScrollContainer = $VBox/ScrollContainer

var line_count: int = 0

func _ready() -> void:
	print("[UI][CombatLog] Ready")
	# Ensure scroll container auto-scrolls to bottom
	if scroll_container:
		scroll_container.get_v_scroll_bar().changed.connect(_on_scroll_changed)

func append(text: String) -> void:
	if not rich_text_label:
		push_warning("[UI][CombatLog] RichTextLabel not found")
		return
	
	# Add timestamp and format the text
	var unix_time = int(Time.get_unix_time_from_system())
	var minutes = int(unix_time / 60.0) % 60
	var seconds = unix_time % 60
	var timestamp = "[%02d:%02d] " % [minutes, seconds]
	var formatted_text = timestamp + text + "\n"
	
	rich_text_label.append_text(formatted_text)
	line_count += 1
	
	print("[UI][CombatLog] append: %s" % text)
	
	# Auto-scroll to bottom after a brief delay to ensure content is updated
	call_deferred("_scroll_to_bottom")

func clear() -> void:
	if rich_text_label:
		rich_text_label.clear()
		line_count = 0
		print("[UI][CombatLog] clear")

func get_line_count() -> int:
	return line_count

func get_text() -> String:
	if rich_text_label:
		return rich_text_label.get_parsed_text()
	return ""

func _scroll_to_bottom() -> void:
	if scroll_container:
		var v_scroll = scroll_container.get_v_scroll_bar()
		v_scroll.value = v_scroll.max_value

func _on_scroll_changed() -> void:
	# Keep scroll at bottom when new content is added
	call_deferred("_scroll_to_bottom")

func _get_entity_display_name(entity: Node) -> String:
	"""Get the proper display name for an entity"""
	if entity == null:
		return "Unknown"
	
	# Try to get display name from entity data first
	if "data" in entity and entity.data != null:
		if "display_name" in entity.data and entity.data.display_name != "":
			return entity.data.display_name
	
	# Fallback to node name
	return entity.name

# Signal connection methods for BattleManager events
func _on_round_started(round_number: int) -> void:
	append("[bold]ROUND %d STARTED[/bold]" % round_number)

func _on_turn_started(actor: Node) -> void:
	var actor_name = _get_entity_display_name(actor)
	append("%s's turn begins" % actor_name)

func _on_turn_ended(actor: Node) -> void:
	var actor_name = _get_entity_display_name(actor)
	append("%s's turn ends" % actor_name)

func _on_damage_dealt(attacker: Node, target: Node, amount: int, dtype: String) -> void:
	var attacker_name = _get_entity_display_name(attacker)
	var target_name = _get_entity_display_name(target)
	append("[color=red]%s deals %d %s damage to %s[/color]" % [attacker_name, amount, dtype, target_name])

func _on_battle_ended(result: String) -> void:
	append("[bold][color=yellow]BATTLE ENDED: %s[/color][/bold]" % result.to_upper())

func _on_status_applied(target: Node, status_name: String) -> void:
	var target_name = _get_entity_display_name(target)
	append("[color=purple]%s gains status: %s[/color]" % [target_name, status_name])

func _on_buff_applied(target: Node, buff_name: String) -> void:
	var target_name = _get_entity_display_name(target)
	append("[color=green]%s gains buff: %s[/color]" % [target_name, buff_name])

func _on_dot_tick(target: Node, damage: int, effect_name: String) -> void:
	var target_name = _get_entity_display_name(target)
	append("[color=orange]%s takes %d damage from %s[/color]" % [target_name, damage, effect_name])
