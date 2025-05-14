extends Node2D

@onready var grid: Grid = $Grid
@onready var turn_counter: Label = $TurnCounter
@onready var samurai: Samurai = $Samurai

var reachable_pivot: Hex

# todo check highlighted_hex + current_unit.hex instead
var highlighted_hex: Hex = null
var last_navigated: Hex = null
var nav_line: Line2D = null
const HEXAGON_DEFAULT_TEXTURE = preload("res://sprites/hexagon.png")
# todo rename to underscore without whitespace
const HEXAGON_FILLED_TEXTURE = preload("res://sprites/hexagon filled.png")

var a_star: AStar3D = AStar3D.new()

@onready var units: Array[Unit] = [samurai]
var turn_order: int = 0
var turn_number: int = 0

var is_there_unit_movement: bool = false
var movement_path: Array[Hex] = []
var movement_turn: int = 1

var unit_offset_to_hex: Vector2

const MOVEMENT_TURNS: int = 10

func _ready():
	block_hexes()
	for unit in units:
		unit.underlying_hex = get_hex_at_pos(unit.position)
	reachable_pivot = units[turn_order].underlying_hex
	fill_reachable(reachable_pivot, 4)
	prepare_navigation()

func _process(_delta):
	highlight_hovered()
	
	if turn_order >= units.size():
		turn_number += 1
		turn_order = 0
		turn_counter.text = "Turn count: " + str(turn_number + 1)
	
	var current_unit: Unit = units[turn_order]
	if highlighted_hex != null:
		show_path(current_unit.underlying_hex.get_grid_coordinates(), highlighted_hex.get_grid_coordinates())
	if !is_there_unit_movement and reachable_pivot != current_unit.underlying_hex:
		reachable_pivot = current_unit.underlying_hex
		grid.reset_grid_textures()
		fill_reachable(reachable_pivot, 4)
		
func _input(event: InputEvent):
	# Check if this is a mouse button event
	if event is InputEventMouseButton:
		# BUTTON_LEFT is a built‑in constant for the left mouse button
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released() and highlighted_hex != null:
			is_there_unit_movement = true
			var start: Hex = units[turn_order].underlying_hex
			var destination: Hex = get_hex_at_cursor()
			
			var id_path: PackedInt64Array = a_star.get_id_path(get_id_by_pos(start.get_grid_coordinates()), get_id_by_pos(destination.get_grid_coordinates()))
			movement_path = []
			unit_offset_to_hex = units[turn_order].position - units[turn_order].underlying_hex.position
			var tween = create_tween()
			for id in id_path:
				var next_hex: Hex = grid.get_hex_by_pos(get_pos_by_id(id))
				
				if next_hex.texture == HEXAGON_FILLED_TEXTURE:
					tween.chain().tween_property(
						units[turn_order],
						"position",
						next_hex.position + unit_offset_to_hex,
						.2
					)
					if id == id_path[id_path.size()-1]:
						await tween.finished
						is_there_unit_movement = false
						units[turn_order].underlying_hex = next_hex

func show_path(start: Vector2, end: Vector2):
	var point_offset: Vector2 = Vector2(0, -20)
	
	var start_hex: Hex = grid.get_hex_by_pos(start)
	var destination_hex: Hex = grid.get_hex_by_pos(end)
	
	if destination_hex != last_navigated and destination_hex != null:
		if nav_line != null:
			self.remove_child(nav_line)
		nav_line = Line2D.new()
		var id_path: PackedInt64Array = a_star.get_id_path(get_id_by_pos(start), get_id_by_pos(end))
		var path_points: Array = [grid.get_hex_by_pos(start).position + point_offset]
		for id in id_path:
			var pos: Vector2 = get_pos_by_id(id)
			path_points.append(grid.get_hex_by_pos(pos).position + point_offset)
		nav_line.points = PackedVector2Array(path_points)
		
		#print(a_star.get_point_count())
		#print(a_star.get_point_ids())
		#print(str(path_points))
		self.add_child(nav_line)
		last_navigated = highlighted_hex

func axial_to_oddr(axial: Vector2) -> Vector2:
	var col = axial.y + (axial.x - (int(axial.x)&1)) / 2
	var row = axial.x
	return Vector2(row, col)

func oddr_to_axial(oddr: Vector2) -> Vector2:
	var q = oddr.y - (oddr.x - (int(oddr.x)&1)) / 2
	var r = oddr.x
	return Vector2(r, q)

func cube_to_axial(cube: Vector3) -> Vector2:
	var q = cube.x
	var r = cube.y
	return Vector2(r, q)

func axial_to_cube(axial: Vector2) -> Vector3:
	var q = axial.y
	var r = axial.x
	var s = -q-r
	return Vector3(q, r, s)

func oddr_to_cube(oddr: Vector2) -> Vector3:
	return axial_to_cube(oddr_to_axial(oddr))

func cube_to_oddr(cube: Vector3) -> Vector2:
	return axial_to_oddr(cube_to_axial(cube))

func get_id_by_pos(pos: Vector2) -> int:
	return pos.x * grid.COLUMNS + pos.y

func get_pos_by_id(id: int) -> Vector2:
	var column: int = id % grid.COLUMNS
	var row: int = (id - column) / grid.COLUMNS
	return Vector2(row, column)

## Defining hexes that're blocked and units cannot pass through
func block_hexes():
	grid.get_hex(2, 2).is_blocked = true
	grid.get_hex(1, 2).is_blocked = true
	grid.get_hex(2, 1).is_blocked = true

## Function that fills hexes that can be reached by current unit
func fill_reachable(start: Hex, speed: int):
	for hex in hex_reachable(start, speed):
		if hex != start:
			hex.texture = HEXAGON_FILLED_TEXTURE

## Preparing AStar2D to work with pathfinding
func prepare_navigation():
	var id_counter = 0
	for i in range(grid.ROWS):
		for j in range(grid.COLUMNS):
			var hex: Hex = grid.get_hex(i, j)
			
			a_star.add_point(id_counter, oddr_to_cube(hex.get_grid_coordinates()))
			id_counter += 1
	for id in a_star.get_point_ids():
		var hex_cube_pos: Vector3 = a_star.get_point_position(id)
		var hex_pos: Vector2 = cube_to_oddr(hex_cube_pos)
		var hex: Hex = grid.get_hex_by_pos(hex_pos)
		for dir in range(6):
			var neighbor = hex_neighbor(hex, dir)
			if !hex.is_blocked and neighbor != null and !neighbor.is_blocked:
				var neighbor_id = neighbor.row * grid.COLUMNS + neighbor.column
				a_star.connect_points(id, neighbor_id)

## Highlight hovered hex using simple shader
func highlight_hovered():
	var hex = get_hex_at_cursor()
	if hex != null:
		if highlighted_hex != hex and highlighted_hex != null:
			highlighted_hex.material = null
		var shader = ShaderMaterial.new()
		shader.shader = preload("res://shaders/selection.gdshader")
		hex.material = shader
	elif highlighted_hex != null:
		highlighted_hex.material = null
	highlighted_hex = hex

## Returns Hex hovered with cursor, if no hex is hovered, then null is returned
func get_hex_at_cursor() -> Hex:
	var mouse_coords: Vector2 = get_global_mouse_position()
	
	return get_hex_at_pos(mouse_coords)

func get_hex_at_pos(position: Vector2) -> Hex:
	var raycast: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(position, position)
	
	raycast.collide_with_areas = true
	raycast.hit_from_inside = true
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(raycast)
	var hex = null
	if result.has("collider"):
		var collider: Node2D = result.get("collider")
		if collider.get_parent() is Hex:
			hex = collider.get_parent()
	return hex

## Returns array of hexes reachable from start Hex having fixed movement speed
func hex_reachable(start: Hex, movement: int):
	var visited: Array = [] # set of hexes
	visited.append(start)
	var fringes = [] # array of arrays of hexes
	fringes.append([start])
	for k in range(1, movement + 1):
		#print("k %s" % k)
		fringes.append([])
		for hex in fringes[k-1]:
			for dir in range(0, 6): # 0 ≤ dir < 6:
				var neighbor: Hex = hex_neighbor(hex, dir)
				if neighbor != null and neighbor not in visited and !neighbor.is_blocked:
					if !visited.has(neighbor):	#add neighbor to visited
						visited.append(neighbor)
					fringes[k].append(neighbor)
					#print("(%s" % neighbor.column + ",%s)" % neighbor.row)
		#print()
	return visited

const oddr_direction_differences = [
	# even rows 
	[[+1,  0], [ 0, -1], [-1, -1], 
	 [-1,  0], [-1, +1], [ 0, +1]],
	# odd rows 
	[[+1,  0], [+1, -1], [ 0, -1], 
	 [-1,  0], [ 0, +1], [+1, +1]],
]

## Returning neighboring Hex in certain direction from provided one
func hex_neighbor(hex: Hex, direction: int) -> Hex:
	var parity = hex.row & 1
	var diff = oddr_direction_differences[parity][direction]
	return grid.get_hex(hex.row + diff[1], hex.column + diff[0])
