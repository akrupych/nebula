extends Sprite2D
class_name Hex

@onready var filled: Sprite2D = $Filled
@onready var hovered: Sprite2D = $Hovered
@onready var obstacle: Sprite2D = $Obstacle

signal clicked(hex: Hex)

var row: int
var column: int
var id: int
var weight: float = 1
var pressed = false

func _ready():
	filled.visible = false
	hovered.visible = false

func set_filled(value: bool):
	filled.visible = value

func set_hovered(value: bool):
	hovered.visible = value

func set_obstacle(texture: Texture2D):
	obstacle.texture = texture

func get_coordinates() -> Vector2:
	return Vector2(row, column)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if pressed && !event.is_pressed(): clicked.emit(self)
		pressed = event.is_pressed()
