extends Camera2D
class_name Camera2DCustom

# Provides compatibility for tests expecting a 'current' property
@export var current: bool = true

func _ready():
	if current:
		make_current()
