extends Node2D

@onready var grid = $Grid

const HEXAGON_FILLED_TEXTURE = preload("res://hexagon filled.png")

func _ready():
	for hex in hex_reachable(grid.get_hex(0, 0), 4):
		hex.texture = HEXAGON_FILLED_TEXTURE

func hex_reachable(start: Hex, movement: int):
	var visited: Array = [] # set of hexes
	visited.append(start)
	var fringes = [] # array of arrays of hexes
	fringes.append([start])

	for k in range(1, movement + 1):
		print("k %s" % k)
		fringes.append([])
		for hex in fringes[k-1]:
			for dir in range(0, 6): # 0 ≤ dir < 6:
				var neighbor: Hex = hex_neighbor(hex, dir)
				if neighbor != null and neighbor not in visited and !neighbor.is_blocked:
					if !visited.has(neighbor):	#add neighbor to visited
						visited.append(neighbor)
					fringes[k].append(neighbor)
					print("(%s" % neighbor.column + ",%s)" % neighbor.row)
		print()

	return visited

const oddr_direction_differences = [
	# even rows 
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	# odd rows 
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]

func hex_neighbor(hex: Hex, direction: int) -> Hex:
	var parity = hex.row & 1
	var diff = oddr_direction_differences[parity][direction]
	return grid.get_hex(hex.column + diff[0], hex.row + diff[1])
