extends CharacterBody2D

@export_range(40.0, 260.0, 1.0) var move_speed := 120.0
@export_range(32.0, 400.0, 1.0) var sight_radius := 240.0
@export_range(64.0, 720.0, 1.0) var lose_radius := 360.0
@export_range(0.5, 8.0, 0.1) var search_duration := 2.5

var player: Node2D
var last_known_position := Vector2.ZERO
var state := "search"
var search_remaining := 0.0

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	add_to_group("police_unit")

func configure(target_player: Node2D) -> void:
	player = target_player
	last_known_position = global_position if player == null else player.global_position

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= sight_radius:
		state = "chase"
		last_known_position = player.global_position
		search_remaining = search_duration
	elif state == "chase" and distance_to_player > lose_radius:
		state = "search"
		search_remaining = search_duration

	if state == "search":
		search_remaining = maxf(0.0, search_remaining - delta)
		if search_remaining == 0.0:
			velocity = Vector2.ZERO
			body_polygon.color = Color(0.435294, 0.584314, 1, 1)
			move_and_slide()
			return

	var target_position := player.global_position if state == "chase" else last_known_position
	var to_target := target_position - global_position
	velocity = Vector2.ZERO if to_target.length() < 8.0 else to_target.normalized() * move_speed
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()
	body_polygon.color = Color(0.129412, 0.298039, 1, 1) if state == "chase" else Color(0.435294, 0.584314, 1, 1)
	move_and_slide()

func is_applying_pressure() -> bool:
	return player != null and state == "chase" and global_position.distance_to(player.global_position) <= sight_radius

func can_despawn() -> bool:
	return state == "search" and search_remaining == 0.0
