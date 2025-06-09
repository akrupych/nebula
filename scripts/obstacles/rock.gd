extends Obstacle
class_name Rock

func _ready() -> void:
	texture = load("res://sprites/rock.png")

func get_directions() -> Array[int]:
	return [2, 4, 0, 0]

func get_weight() -> int:
	return 10
