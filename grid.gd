extends Node2D

const COLUMNS = 11
const ROWS = 8

@onready var hexagon: Sprite2D = $Hexagon

@onready var hexagon_right: Sprite2D = $Hexagon2
@onready var hexagon_down: Sprite2D = $Hexagon3

@export var grid: Array = []


func _ready():
	var sample_hex: Sprite2D = hexagon.duplicate()
	
	var offset_right: Vector2 = hexagon_right.position - hexagon.position
	var offset_down: Vector2 = hexagon_down.position - hexagon.position
	
	for i in range(COLUMNS):
		grid.append([])
		for j in range(ROWS):
			var new_hex: Sprite2D = sample_hex.duplicate()
			
			new_hex.position += offset_right * i + Vector2(offset_down.x * (j % 2), offset_down.y * j)
			
			self.add_child(new_hex)
			grid[i].append(new_hex)
	
