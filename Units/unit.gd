@tool
extends Path2D

class_name Unit

signal walk_finished

@export var grid: Grid = preload("res://GameBoard/grid.tres")
@export var move_range := 6
@export var skin: Texture : set = set_skin
@export var skin_offset := Vector2.ZERO : set = set_skin_offset
@export var move_speed := 600.0

var cell := Vector2.ZERO : set = set_cell
var is_selected := false : set = set_is_selected

var _is_walking := false : set = _set_is_walking

@onready var _sprite: Sprite2D = %Sprite
@onready var _anim_player: AnimationPlayer = %AnimationPlayer
@onready var _path_follow: PathFollow2D = %PathFollow2D

const INFINITELY_SMALL_AMOUNT = 0.0001

func _ready() -> void:
	set_process(false)
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta

	if _path_follow.progress_ratio >= 1.0:
		self._is_walking = false
		# had to set to this value, otherwise "Zero-length interval" errors
		_path_follow.progress = INFINITELY_SMALL_AMOUNT
		position = grid.calculate_map_position(cell)
		curve.clear_points()

		emit_signal("walk_finished")


func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)

	cell = path[-1]
	self._is_walking = true


func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)


func set_is_selected(value: bool) -> void:
	is_selected = value
	if is_selected:
		_anim_player.play("selected")
	else:
		_anim_player.play("idle")


func set_skin(value: Texture) -> void:
	skin = value

	if not _sprite:
		await self.ready
	_sprite.texture = value


func set_skin_offset(value: Vector2) -> void:
	skin_offset = value
	if not _sprite:
		await self.ready
	_sprite.position = value


func _set_is_walking(value: bool) -> void:
	_is_walking = value
	set_process(_is_walking)
