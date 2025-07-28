# EventBus.gd — tiny signal-only singleton to decouple systems.
extends Node
class_name EventBus
signal event(kind: String, payload: Dictionary)

func send_event(kind: String, payload: Dictionary):
	emit_signal("event", kind, payload)
	
#EOF
