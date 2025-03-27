extends Node2D
class_name DrawingHelper

var shape_type: String = "rectangle"  # "rectangle", "circle", or "polygon"
var start_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO
var points: Array = []  # For polygon

func _draw() -> void:
	match shape_type:
		"rectangle":
			# Calculate size and ensure positive values
			var size = current_pos - start_pos
			var draw_pos = start_pos
			
			if size.x < 0:
				draw_pos.x += size.x
				size.x = -size.x
			if size.y < 0:
				draw_pos.y += size.y
				size.y = -size.y
				
			# Draw rectangle from actual position (don't use transform)
			var rect = Rect2(draw_pos - global_position, size)
			draw_rect(rect, Color(0.2, 0.2, 0.9, 0.3), true)
			draw_rect(rect, Color(1, 1, 1, 0.8), false, 2.0)
		
		"circle":
			var size = current_pos - start_pos
			var radius = size.length() / 2
			var center = (start_pos + current_pos) / 2 - global_position
			
			draw_circle(center, radius, Color(0.2, 0.2, 0.9, 0.3))
			draw_arc(center, radius, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)
		
		"polygon":
			if points.size() < 2:
				return
			
			# Draw lines between points
			for i in range(points.size()):
				var start = points[i] - global_position
				var end = points[(i + 1) % points.size()] - global_position
				draw_line(start, end, Color(1, 1, 1, 0.8), 2.0)
			
			# Draw points
			for point in points:
				draw_circle(point - global_position, 5, Color(1, 1, 1, 0.8))
			
			# If in drawing mode, also draw to current mouse position
			if current_pos != Vector2.ZERO and points.size() > 0:
				draw_line(points[points.size()-1] - global_position, 
						  current_pos - global_position, 
						  Color(1, 1, 1, 0.5), 2.0)
