extends Node2D
class_name Battle

@onready var grid: Grid = $Grid
@onready var current_turn_label: Label = $CurrentTurn
@onready var units: Array[Unit] = []

const SAMURAI = preload("res://scenes/samurai.tscn")

var active_unit_index: int = 0
var current_turn: int = 0
var ignore_clicks: bool = false

func _ready():
	generate_obstacles()
	generate_units()
	grid.show_reachable_hexes(get_current_unit())

func get_current_unit() -> Unit:
	return units[active_unit_index]

func generate_obstacles():
	grid.add_obstacle(2, 2, Rock.new())
	grid.add_obstacle(5, 5, Lake.new())

func generate_units():
	var samurai = SAMURAI.instantiate()
	units.append(samurai)
	grid.place_unit(samurai, 0, 0)
	for unit in units:
		add_child(unit)
		unit.set_idle()

func _on_hex_clicked(hex: Hex):
	if ignore_clicks: return
	ignore_clicks = true
	var unit = get_current_unit()
	if hex == unit.hex: return
	grid.hide_reachable_hexes()
	unit.set_moving()
	# remove current unit hex and unreachable hexes from path
	var path = grid.find_path(unit.hex, hex)
	path.remove_at(0)
	var distance = 0.0
	for i in path.size():
		if i < path.size(): distance += path[i].weight
		if distance > unit.speed: path.pop_back()
	# run animation
	var prev_hex = unit.hex
	for next_hex in path:
		if (next_hex.position.x > prev_hex.position.x): unit.flip_h = !unit.facing_right
		else: unit.flip_h = unit.facing_right
		unit.z_index = next_hex.row + 1
		var tween = create_tween()
		tween.tween_property(unit, "position", next_hex.position - Vector2(0, 50), 0.5)
		await tween.finished
		prev_hex = next_hex
	# post-animation updates
	unit.hex = path[-1]
	unit.set_idle()
	grid.show_reachable_hexes(unit)
	# end turn
	active_unit_index += 1
	if active_unit_index >= units.size():
		current_turn += 1
		active_unit_index = 0
		current_turn_label.text = "Current turn: " + str(current_turn + 1)
	ignore_clicks = false
