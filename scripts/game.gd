extends Node2D

@onready var grid = $Grid

var highlighted_hex: Hex = null
const HEXAGON_FILLED_TEXTURE = preload("res://sprites/hexagon filled.png")

func _ready():
	block_hexes()
	var start = grid.get_hex(0, 0)
	fill_reachable(start, 4)

func _process(_delta):
	highlight_hovered()

func block_hexes():
	grid.get_hex(2, 2).is_blocked = true
	grid.get_hex(2, 1).is_blocked = true

func fill_reachable(start: Hex, speed: int):
	for hex in hex_reachable(start, speed):
		if hex != start:
			hex.texture = HEXAGON_FILLED_TEXTURE

func highlight_hovered():
	var mouse_coords: Vector2 = get_global_mouse_position()
	
	var raycast: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(mouse_coords, mouse_coords)
	
	raycast.collide_with_areas = true
	raycast.hit_from_inside = true
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(raycast)
	var hex = null
	if result.has("collider"):
		var collider: Node2D = result.get("collider")
		if collider.get_parent() is Hex:
			hex = collider.get_parent()
	if hex != null:
		if highlighted_hex != hex and highlighted_hex != null:
			highlighted_hex.material = null
		var shader = ShaderMaterial.new()
		shader.shader = preload("res://shaders/selection.gdshader")
		hex.material = shader
	elif highlighted_hex != null:
		highlighted_hex.material = null
	highlighted_hex = hex

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
