extends Sprite2D
class_name Hex

@export var row: int
@export var column: int
@export var is_blocked: bool = false

func _process(_delta):
	if is_blocked and self.texture != null:
		self.texture = null
		self.remove_child(self.get_child(0))
		self.remove_child(self.get_child(0))

func get_grid_coordinates() -> Vector2:
	return Vector2(row, column)
