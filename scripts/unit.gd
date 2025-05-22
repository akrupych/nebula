extends AnimatedSprite2D
class_name Unit

var hex: Hex = null
var speed: int = 0
var facing_right: bool = true

func set_idle():
	play("idle")

func set_moving():
	play("move")

func set_striking():
	play("strike")
