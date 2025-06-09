extends Node2D
class_name Grid

const COLUMNS = 18
const ROWS = 9

@onready var initial_hex: Hex = $InitialHex

var hexes: Array = []
var a_star: AStar2D = AStar2D.new()

func _ready():
	var offset_right = Vector2(63, 0)
	var offset_down = Vector2(32, 55)
	var id = 0
	# fill child hexes
	for row in ROWS:
		for column in COLUMNS:
			var hex: Hex = initial_hex.duplicate()
			hex.row = row
			hex.column = column
			hex.id = id
			hex.position += offset_right * column + offset_down * Vector2(row % 2, row)
			a_star.add_point(hex.id, hex.position)
			var label = Label.new()
			label.text = str(row) + "," + str(column)
			hex.add_child(label)
			add_child(hex)
			hexes.append(hex)
			id += 1
	# kill patient zero
	remove_child(initial_hex)
	# connect points in graph
	for hex in hexes:
		for neighbor in get_neighbors(hex):
			a_star.connect_points(hex.id, neighbor.id)

func add_obstacle(row: int, column: int, obstacle: Obstacle):
	var center_hex = get_hex(row, column)
	obstacle.position = center_hex.position - Vector2(0, 30)
	var hexes = [center_hex]
	for direction in obstacle.get_directions():
		hexes.append(get_neighbor(hexes[-1], direction))
	hexes.filter(func(it): it != null)
	var bottom_row = center_hex.row
	for hex in hexes:
		hex.weight = obstacle.get_weight()
		a_star.set_point_weight_scale(hex.id, hex.weight)
		if (hex.row > bottom_row): bottom_row = hex.row
	obstacle.z_index = bottom_row + 1
	add_child(obstacle)
	
func place_unit(unit: Unit, row: int, column: int):
	var hex = get_hex(row, column)
	unit.hex = hex
	unit.position = hex.position - Vector2(0, 50)
	unit.z_index = row + 1

# highlight hexes currently reachable by a unit
func show_reachable_hexes(unit: Unit):
	var reachable = []
	# we have to check path length according to hex weights for every hex in a diamond
	for row in range(unit.hex.row - unit.speed, unit.hex.row + unit.speed + 1):
		for column in range(unit.hex.column - unit.speed, unit.hex.column + unit.speed + 1):
			var hex = get_hex(row, column)
			if hex != null && hex != unit.hex:
				var distance = 0.0
				for id in a_star.get_id_path(unit.hex.id, hex.id):
					distance += a_star.get_point_weight_scale(id)
				distance -= unit.hex.weight
				if (distance <= unit.speed): hex.set_filled(true)

# clear highlighted hexes
func hide_reachable_hexes():
	for hex in hexes: hex.set_filled(false)

# get existing neighboring hexes
func get_neighbors(hex: Hex) -> Array[Hex]:
	var neighbors: Array[Hex] = []
	print("--- " + str(hex) + " ---")
	for direction in 6:
		var neighbor = get_neighbor(hex, direction)
		print("direction " + str(direction) + " hex " + str(neighbor))
		if neighbor != null: neighbors.append(neighbor)
	return neighbors

var odd = [[+1, 0], [0, -1], [-1, -1], [-1, 0], [-1, +1], [0, +1]]
var even = [[+1, 0], [+1, -1], [0, -1], [-1, 0], [ 0, +1], [+1, +1]]

func get_neighbor(hex: Hex, direction: int) -> Hex:
	var diffs = even if hex.row & 1 else odd
	var diff = diffs[direction]
	return get_hex(hex.row + diff[1], hex.column + diff[0])

# find hex by coordinates
func get_hex(row: int, column: int) -> Hex:
	if row >= 0 and row < ROWS and column >= 0 and column < COLUMNS:
		return hexes[row * COLUMNS + column]
	return null

# find path, al least partial, between start and end hexes (including both)
func find_path(start: Hex, end: Hex) -> Array:
	var ids = Array(a_star.get_id_path(start.id, end.id, true))
	return ids.map(func(id): return hexes[id])
