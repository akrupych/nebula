extends AnimatedSprite2D
class_name Unit

@export var hex: Hex = null
@export var speed: int = 0

func get_position_at(hex: Hex) -> Vector2:
	return hex.position + position - self.hex.position
