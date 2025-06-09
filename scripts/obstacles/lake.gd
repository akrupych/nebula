extends Obstacle
class_name Lake

func _ready() -> void:
	texture = load("res://sprites/lake.png")

func get_directions() -> Array[int]:
	return [0, 1, 3, 3, 3, 5]

func get_weight() -> int:
	return 5
