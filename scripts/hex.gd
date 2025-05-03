extends Sprite2D
class_name Hex

@export var column: int
@export var row: int
@export var is_blocked: bool = false

func _process(_delta):
	if is_blocked and self.texture != null:
		self.texture = null
		self.remove_child(self.get_child(0))
