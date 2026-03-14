extends CharacterBody2D

signal harmed(source: Node2D)

@export_enum("pedestrian", "traffic") var actor_type := "pedestrian"
@export var movement_axis := Vector2.RIGHT
@export_range(16.0, 240.0, 1.0) var patrol_distance := 72.0
@export_range(0.0, 240.0, 1.0) var move_speed := 52.0
@export_range(0.0, 4.0, 0.1) var pause_duration := 0.8
@export var harmed_flash_time := 0.45

var anchor_position := Vector2.ZERO
var direction := 1.0
var pause_remaining := 0.0
var harmed_flash_remaining := 0.0

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	anchor_position = global_position
	movement_axis = movement_axis.normalized() if movement_axis != Vector2.ZERO else Vector2.RIGHT
	add_to_group("civilian")
	add_to_group("civilian_witness")
	if actor_type == "pedestrian":
		add_to_group("civilian_pedestrian")
	else:
		add_to_group("civilian_vehicle")
	rotation = movement_axis.angle()

func _physics_process(delta: float) -> void:
	harmed_flash_remaining = maxf(0.0, harmed_flash_remaining - delta)
	body_polygon.color = _get_body_color()

	if pause_remaining > 0.0:
		pause_remaining = maxf(0.0, pause_remaining - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_position := anchor_position + movement_axis * patrol_distance * direction
	var to_target := target_position - global_position
	if to_target.length() <= 6.0:
		direction *= -1.0
		pause_remaining = pause_duration
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * move_speed
		if velocity != Vector2.ZERO:
			rotation = velocity.angle()
	move_and_slide()

func register_harm(source: Node2D) -> void:
	harmed_flash_remaining = harmed_flash_time
	pause_remaining = maxf(pause_remaining, 0.4)
	harmed.emit(source)

func _get_body_color() -> Color:
	if harmed_flash_remaining > 0.0:
		return Color(1, 0.2, 0.2, 1)
	if actor_type == "pedestrian":
		return Color(0.152941, 0.921569, 0.282353, 1)
	return Color(0.105882, 0.760784, 1, 1)
