extends Control

@export_enum("player", "car", "civilian", "traffic", "police", "impact", "barrier") var icon_kind := "player"
@export var primary_color := Color.WHITE
@export var secondary_color := Color(0, 0, 0, 0)

func _ready() -> void:
	custom_minimum_size = Vector2(24, 16)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	match icon_kind:
		"player", "civilian", "police", "impact":
			var points := PackedVector2Array([
				Vector2(rect.position.x + rect.size.x * 0.82, rect.position.y + rect.size.y * 0.5),
				Vector2(rect.position.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.1),
				Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y + rect.size.y * 0.5),
				Vector2(rect.position.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.9),
			])
			draw_colored_polygon(points, primary_color)
		"car", "traffic", "barrier":
			draw_rect(Rect2(Vector2(2, 2), Vector2(rect.size.x - 4, rect.size.y - 4)), primary_color)
			if icon_kind == "car" or icon_kind == "traffic":
				draw_rect(Rect2(Vector2(rect.size.x * 0.32, 3), Vector2(rect.size.x * 0.36, rect.size.y - 6)), secondary_color)
			elif icon_kind == "barrier":
				draw_rect(Rect2(Vector2(2, rect.size.y * 0.4), Vector2(rect.size.x - 4, rect.size.y * 0.2)), secondary_color)

