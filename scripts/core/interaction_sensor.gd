extends Area2D

var candidates: Array[Node2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func get_closest_candidate(from_position: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_distance := INF
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate.has_method("can_enter") and not candidate.can_enter():
			continue
		var distance := from_position.distance_to(candidate.global_position)
		if distance < closest_distance:
			closest = candidate
			closest_distance = distance
	return closest

func _on_area_entered(area: Area2D) -> void:
	_track(area)

func _on_area_exited(area: Area2D) -> void:
	_untrack(area)

func _on_body_entered(body: Node2D) -> void:
	_track(body)

func _on_body_exited(body: Node2D) -> void:
	_untrack(body)

func _track(candidate: Node) -> void:
	var node := _resolve_candidate(candidate)
	if node != null and not candidates.has(node):
		candidates.append(node)

func _untrack(candidate: Node) -> void:
	var node := _resolve_candidate(candidate)
	if node != null:
		candidates.erase(node)

func _resolve_candidate(candidate: Node) -> Node2D:
	if candidate is Node2D and candidate.has_method("can_enter"):
		return candidate
	if candidate.get_parent() is Node2D and candidate.get_parent().has_method("can_enter"):
		return candidate.get_parent()
	return null
