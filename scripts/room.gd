extends Node2D
class_name Room

# Room properties
var id: int
var shape_type: String  # "rectangle", "circle", or "polygon"
var bounds: Rect2 = Rect2(0, 0, 100, 100)
var points: Array = []  # For polygon shapes
var texture_path: String = ""
var is_wall: bool = false  # True for walls (no inner texture), False for rooms (textured inside)

# Drawing colors
var line_color: Color = Color(1, 1, 1, 0.8)  # Border color
var fill_color: Color = Color(0.2, 0.2, 0.9, 0.5)  # Fill color for rooms
var selected: bool = false

func _init(p_id: int, p_shape: String, p_position: Vector2, p_size: Vector2) -> void:
	id = p_id
	shape_type = p_shape
	bounds = Rect2(p_position, p_size)

func _draw() -> void:
	match shape_type:
		"rectangle":
			draw_rect(Rect2(Vector2.ZERO, bounds.size), fill_color, true)
			draw_rect(Rect2(Vector2.ZERO, bounds.size), line_color, false, 2.0)
		"circle":
			var radius = min(bounds.size.x, bounds.size.y) / 2
			draw_circle(Vector2(radius, radius), radius, fill_color)
			draw_arc(Vector2(radius, radius), radius, 0, TAU, 32, line_color, 2.0)
		"polygon":
			if points.size() > 2:
				draw_colored_polygon(points, fill_color)
				for i in range(points.size()):
					var start = points[i]
					var end = points[(i + 1) % points.size()]
					draw_line(start, end, line_color, 2.0)

func set_selected(is_selected: bool) -> void:
	selected = is_selected
	if selected:
		line_color = Color(1, 0.8, 0, 1.0)  # Highlight selected rooms
	else:
		line_color = Color(1, 1, 1, 0.8)
	queue_redraw()

func contains_point(point: Vector2) -> bool:
	# Check if point is inside this room
	match shape_type:
		"rectangle":
			return bounds.has_point(point)
		"circle":
			var radius = min(bounds.size.x, bounds.size.y) / 2
			var center = Vector2(bounds.position.x + radius, bounds.position.y + radius)
			return point.distance_to(center) <= radius
		"polygon":
			if points.size() < 3:
				return false
			
			var transformed_points = []
			for p in points:
				transformed_points.append(p + bounds.position)
			
			return Geometry2D.is_point_in_polygon(point, transformed_points)
	return false
