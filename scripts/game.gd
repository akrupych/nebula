extends Node2D

@onready var grid: Grid = $Grid
@onready var current_turn_label: Label = $CurrentTurn
@onready var samurai: Samurai = $Samurai
@onready var units: Array[Unit] = [samurai]

var highlighted_hex: Hex = null

var _active_unit_index: int = 0
var _current_turn: int = 0

func _ready():
	generate_obstacles()
	for unit in units: unit.hex = get_hex_at_pos(unit.position)
	grid.show_reachable_hexes(get_current_unit())

func _process(_delta):
	highlight_hovered()

func get_current_unit() -> Unit:
	return units[_active_unit_index]

func generate_obstacles():
	# TODO: use different textures for each hex
	var image = Image.load_from_file("res://sprites/obstacle.png")
	var texture = ImageTexture.create_from_image(image)
	grid.add_obstacle(Vector2(1, 2), 3, texture)
	grid.add_obstacle(Vector2(2, 1), 3, texture)
	grid.add_obstacle(Vector2(2, 2), 3, texture)

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

func highlight_hovered():
	var hex = get_hex_at_pos(get_global_mouse_position())
	if (highlighted_hex != hex):
		if highlighted_hex != null: highlighted_hex.set_hovered(false)
		if hex != null: hex.set_hovered(true)
		highlighted_hex = hex

func _on_hex_clicked(hex: Hex):
	var unit = get_current_unit()
	if hex == unit.hex: return
	grid.hide_reachable_hexes()
	# remove current unit hex and unreachable hexes from path
	var path = grid.find_path(unit.hex, hex)
	path.remove_at(0)
	var distance = 0.0
	for i in path.size():
		if i < path.size(): distance += path[i].weight
		if distance > unit.speed: path.pop_back()
	# run animation
	var tween = create_tween()
	for next_hex in path:
		tween.chain().tween_property(unit, "position", unit.get_position_at(next_hex), 0.2)
	# post-animation updates
	await tween.finished
	unit.hex = path[-1]
	grid.show_reachable_hexes(unit)
	# end turn
	_active_unit_index += 1
	if _active_unit_index >= units.size():
		_current_turn += 1
		_active_unit_index = 0
		current_turn_label.text = "Current turn: " + str(_current_turn + 1)
