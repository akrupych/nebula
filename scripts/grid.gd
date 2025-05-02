extends Node2D
class_name Grid

const COLUMNS = 11
const ROWS = 8

@onready var hexagon: Hex = $Hex

@onready var hexagon_right: Hex = $Hex2
@onready var hexagon_down: Hex = $Hex3

@export var grid: Array = []

func _ready():
	var sample_hex: Hex = hexagon.duplicate()
	
	var offset_right: Vector2 = hexagon_right.position - hexagon.position
	var offset_down: Vector2 = hexagon_down.position - hexagon.position
	
	for i in range(COLUMNS):
		grid.append([])
		for j in range(ROWS):
			var new_hex: Hex = sample_hex.duplicate()
			
			new_hex.position += offset_right * i + Vector2(offset_down.x * (j % 2), offset_down.y * j)
			
			new_hex.column = i
			new_hex.row = j
			var label = Label.new()
			
			label.text = str(i) + ", " + str(j)
			new_hex.add_child(label)
			self.add_child(new_hex)
			grid[i].append(new_hex)

func get_hex(row: int, column: int) -> Hex:
	if row >= 0 and row < ROWS and column >= 0 and column < COLUMNS:
		return grid[row][column]
	
	return null
