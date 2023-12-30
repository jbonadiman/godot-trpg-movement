extends Node2D

class_name GameBoard

const DIRECTIONS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
]

@export var grid: Resource = preload("res://GameBoard/grid.tres")
@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath

var _active_unit: Unit
var _walkable_cells := []
var _units := {}

func _ready() -> void:
	_reinitialize()


func _reinitialize() -> void:
	_units.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue

		_units[unit.cell] = unit


func get_walkable_cells(unit: Unit) -> Array:
	return _flood_fill(unit.cell, unit.move_range)


func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	var max_distance_reached := func(current_cell: Vector2) -> bool:
		var difference: Vector2 = (current_cell - cell).abs()
		var distance := int(difference.x + difference.y)
		return distance > max_distance

	var array := []
	var stack := [cell]

	while not stack.is_empty():
		var current: Vector2 = stack.pop_back()

		if not grid.is_within_bounds(current): continue
		if current in array: continue
		if max_distance_reached.call(current): continue

		array.append(current)

		for direction: Vector2 in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			if _units.has(coordinates):
				continue
			if coordinates in array:
				continue
			stack.append(coordinates)
	return array


func _select_unit(cell: Vector2) -> void:
	if not _units.has(cell):
		return

	_active_unit = _units[cell]
	_active_unit.is_selected = true
	_walkable_cells = get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path.initialize(_walkable_cells)


func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()


func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


func _move_active_unit(new_cell: Vector2) -> void:
	if _units.has(new_cell) or not new_cell in _walkable_cells:
		return

	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	_deselect_active_unit()
	_active_unit.walk_along(_unit_path.current_path)

	await _active_unit.walk_finished
	_clear_active_unit()


func _on_cursor_accepted_pressed(cell: Vector2) -> void:
	if not _active_unit:
		_select_unit(cell)
	elif _active_unit.is_selected:
		_move_active_unit(cell)


func _on_cursor_moved(new_cell: Vector2) -> void:
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)


func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()
