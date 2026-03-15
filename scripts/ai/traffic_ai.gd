extends CharacterBody2D

signal harmed(source: Node2D)

@export_range(24.0, 180.0, 1.0) var move_speed := 70.0
@export_range(24.0, 120.0, 1.0) var vehicle_look_ahead := 54.0
@export_range(24.0, 96.0, 1.0) var pedestrian_look_ahead := 44.0
@export var harmed_flash_time := 0.45
@export_range(0.0, 2.0, 0.05) var respawn_pause := 0.35

var harmed_flash_remaining := 0.0
var pause_remaining := 0.0
var world_path_points := PackedVector2Array()
var path_target_index := 1
var default_collision_layer := 0
var default_collision_mask := 0

@onready var body_polygon: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	add_to_group("civilian")
	add_to_group("civilian_vehicle")
	add_to_group("civilian_witness")
	add_to_group("traffic_vehicle")

func _physics_process(delta: float) -> void:
	harmed_flash_remaining = maxf(0.0, harmed_flash_remaining - delta)
	pause_remaining = maxf(0.0, pause_remaining - delta)
	body_polygon.color = _get_body_color()

	if pause_remaining > 0.0 or world_path_points.size() < 2:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_follow_world_path()
	move_and_slide()

func set_world_path(points: PackedVector2Array) -> void:
	world_path_points = points
	path_target_index = 1 if world_path_points.size() >= 2 else 0
	if world_path_points.size() >= 1:
		global_position = world_path_points[0]

func set_path_active(is_active: bool) -> void:
	visible = is_active
	set_physics_process(is_active)
	collision_layer = default_collision_layer if is_active else 0
	collision_mask = default_collision_mask if is_active else 0
	if collision_shape != null:
		collision_shape.disabled = not is_active
	if not is_active:
		velocity = Vector2.ZERO

func register_harm(source: Node2D) -> void:
	harmed_flash_remaining = harmed_flash_time
	pause_remaining = maxf(pause_remaining, 0.4)
	harmed.emit(source)

func _follow_world_path() -> void:
	var target_position := world_path_points[path_target_index]
	var to_target := target_position - global_position
	if to_target.length() <= 6.0:
		_advance_path_target()
		target_position = world_path_points[path_target_index]
		to_target = target_position - global_position

	var direction_vector := to_target.normalized() if to_target.length() > 0.0 else Vector2.ZERO
	velocity = direction_vector * move_speed
	if direction_vector != Vector2.ZERO and (_has_pedestrian_ahead(direction_vector) or _has_vehicle_ahead(direction_vector)):
		velocity = Vector2.ZERO
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()

func _advance_path_target() -> void:
	path_target_index += 1
	if path_target_index < world_path_points.size():
		return
	global_position = world_path_points[0]
	path_target_index = 1 if world_path_points.size() >= 2 else 0
	pause_remaining = respawn_pause

func _has_pedestrian_ahead(direction_vector: Vector2) -> bool:
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if candidate == self or not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		if not pedestrian.visible:
			continue
		var offset: Vector2 = pedestrian.global_position - global_position
		if offset.length() > pedestrian_look_ahead:
			continue
		var forward_distance := direction_vector.dot(offset)
		if forward_distance <= 0.0:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance <= 18.0:
			return true
	return false

func _has_vehicle_ahead(direction_vector: Vector2) -> bool:
	for candidate in get_tree().get_nodes_in_group("traffic_vehicle"):
		if candidate == self or not (candidate is Node2D):
			continue
		var vehicle := candidate as Node2D
		if not vehicle.visible:
			continue
		var offset: Vector2 = vehicle.global_position - global_position
		if offset.length() > vehicle_look_ahead:
			continue
		var forward_distance := direction_vector.dot(offset)
		if forward_distance <= 0.0:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance > 20.0:
			continue
		var vehicle_forward := Vector2.RIGHT.rotated(vehicle.rotation)
		if direction_vector.dot(vehicle_forward) >= 0.35:
			return true
	return false

func _get_body_color() -> Color:
	return Color(1, 0.2, 0.2, 1) if harmed_flash_remaining > 0.0 else Color(0.105882, 0.760784, 1, 1)
