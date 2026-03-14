extends Node

signal crime_reported(event: Dictionary)

@export_range(32.0, 360.0, 1.0) var witness_radius := 180.0

func report_vehicle_theft(source: Node2D, target: Node2D) -> bool:
	return _report_crime("vehicle_theft", source, target, target.global_position, 1)

func report_pedestrian_assault(source: Node2D, target: Node2D) -> bool:
	return _report_crime("assault", source, target, target.global_position, 1)

func report_harmful_collision(source: Node2D, target: Node2D) -> bool:
	return _report_crime("harmful_collision", source, target, target.global_position, 2)

func _report_crime(event_type: String, source: Node2D, target: Node2D, world_position: Vector2, wanted_value: int) -> bool:
	var witnesses := _count_witnesses(world_position, target)
	if witnesses == 0:
		return false

	crime_reported.emit({
		"type": event_type,
		"source": source,
		"target": target,
		"position": world_position,
		"witness_count": witnesses,
		"wanted_value": wanted_value,
	})
	return true

func _count_witnesses(world_position: Vector2, excluded_target: Node2D) -> int:
	var witness_count := 0
	for candidate in get_tree().get_nodes_in_group("civilian_witness"):
		if candidate == excluded_target or not (candidate is Node2D):
			continue
		if candidate.global_position.distance_to(world_position) <= witness_radius:
			witness_count += 1
	return witness_count
