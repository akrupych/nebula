extends Node2D
class_name Grid

const COLUMNS = 11
const ROWS = 8

const HEXAGON_DEFAULT_TEXTURE = preload("res://sprites/hexagon.png")

@onready var hexagon: Hex = $Hex

@onready var hexagon_right: Hex = $Hex2
@onready var hexagon_down: Hex = $Hex3

@export var grid: Array[Array] = []

func _ready():
	prepare_grid()
	delete_initial_hexes()
	var hex = get_hex_by_id(10)
	print(str(hex.row) + ":" + str(hex.column))

func prepare_grid():
	var sample_hex: Hex = hexagon.duplicate()
	
	var offset_right: Vector2 = hexagon_right.position - hexagon.position
	var offset_down: Vector2 = hexagon_down.position - hexagon.position
	
	var id = 0
	for i in range(ROWS):
		grid.append([])
		for j in range(COLUMNS):
			var new_hex: Hex = sample_hex.duplicate()
			
			new_hex.position += offset_right * j + Vector2(offset_down.x * (i % 2), offset_down.y * i)
			
			new_hex.column = j
			new_hex.row = i
			new_hex.id = id
			
			id += 1
			var label = Label.new()
			
			label.text = str(i) + ", " + str(j)
			new_hex.add_child(label)
			self.add_child(new_hex)
			grid[i].append(new_hex)

func reset_grid_textures():
	for i in range(ROWS):
		for j in range(COLUMNS):
			grid[i][j].texture = HEXAGON_DEFAULT_TEXTURE

func delete_initial_hexes():
	self.remove_child(hexagon)
	self.remove_child(hexagon_down)
	self.remove_child(hexagon_right)

func get_hex(row: int, column: int) -> Hex:
	if row >= 0 and row < ROWS and column >= 0 and column < COLUMNS:
		return grid[row][column]
	return null

func get_hex_by_id(id: int) -> Hex:
	return grid[id / COLUMNS][id % COLUMNS]
