extends Node2D
class_name Grid

const COLUMNS = 11
const ROWS = 8

@onready var _initial_hex: Hex = $InitialHex

var _hexes: Array = []
var _a_star: AStar2D = AStar2D.new()

func _ready():
	var offset_right = Vector2(63, 0)
	var offset_down = Vector2(32, 55)
	var id = 0
	# fill child hexes
	for row in ROWS:
		for column in COLUMNS:
			var hex: Hex = _initial_hex.duplicate()
			hex.row = row
			hex.column = column
			hex.id = id
			hex.position += offset_right * column + offset_down * Vector2(row % 2, row)
			_a_star.add_point(hex.id, hex.position)
			var label = Label.new()
			label.text = str(row) + "," + str(column)
			hex.add_child(label)
			add_child(hex)
			_hexes.append(hex)
			id += 1
	# kill patient zero
	remove_child(_initial_hex)
	# connect points in graph
	for hex in _hexes:
		for neighbor in get_neighbors(hex):
			_a_star.connect_points(hex.id, neighbor.id)

# coordinates are hex row and column, weight is hex difficulty to pass
func add_obstacle(coordinates: Vector2, weight: float, texture: Texture2D):
	var hex = get_hex(coordinates.x, coordinates.y)
	hex.weight = weight
	hex.set_obstacle(texture)
	_a_star.set_point_weight_scale(hex.id, weight)

# highlight hexes currently reachable by a unit
func show_reachable_hexes(unit: Unit):
	var reachable = []
	# we have to check path length according to hex weights for every hex in a diamond
	for row in range(unit.hex.row - unit.speed, unit.hex.row + unit.speed + 1):
		for column in range(unit.hex.column - unit.speed, unit.hex.column + unit.speed + 1):
			var hex = get_hex(row, column)
			if hex != null && hex != unit.hex:
				var distance = 0.0
				for id in _a_star.get_id_path(unit.hex.id, hex.id):
					distance += _a_star.get_point_weight_scale(id)
				distance -= unit.hex.weight
				if (distance <= unit.speed): hex.set_filled(true)

# clear highlighted hexes
func hide_reachable_hexes():
	for hex in _hexes: hex.set_filled(false)

# get existing neighboring hexes
func get_neighbors(hex: Hex) -> Array[Hex]:
	var odd = [[+1, 0], [0, -1], [-1, -1], [-1, 0], [-1, +1], [0, +1]]
	var even = [[+1, 0], [+1, -1], [0, -1], [-1, 0], [ 0, +1], [+1, +1]]
	var diffs = even if hex.row & 1 else odd
	var neighbors: Array[Hex] = []
	for direction in 6:
		var diff = diffs[direction]
		var neighbor = get_hex(hex.row + diff[1], hex.column + diff[0])
		if neighbor != null: neighbors.append(neighbor)
	return neighbors

# find hex by coordinates
func get_hex(row: int, column: int) -> Hex:
	if row >= 0 and row < ROWS and column >= 0 and column < COLUMNS:
		return _hexes[row * COLUMNS + column]
	return null

# find path, al least partial, between start and end hexes (including both)
func find_path(start: Hex, end: Hex) -> Array:
	var ids = Array(_a_star.get_id_path(start.id, end.id, true))
	return ids.map(func(id): return _hexes[id])
