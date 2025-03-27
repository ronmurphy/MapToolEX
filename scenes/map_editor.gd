extends Node2D
# Tool selection
enum Tools { SELECT, RECTANGLE, CIRCLE, POLYGON }
var current_tool = Tools.SELECT
var drawing = false
var start_position = Vector2.ZERO
var temp_shape = null
var rooms = []
var next_room_id = 1

# For polygon tool
var polygon_points = []
var temp_polygon = null
var drawing_polygon = false

var drawing_helper: DrawingHelper = null


# Connect UI buttons to tool selection
func _ready() -> void:
	print("Map Editor is ready!")


func _on_rectangle_button_pressed() -> void:
	current_tool = Tools.RECTANGLE
	null


func _on_circle_button_pressed() -> void:
	current_tool = Tools.CIRCLE
	null


func _on_polygon_button_pressed() -> void:
	current_tool = Tools.POLYGON
	null


# Called every frame
func _process(delta):
	# Delta is the time since the last frame (useful for animations)
	pass


func load_map_image(path: String) -> void:
	print("Attempting to load image from: " + path)
	# Load the image
	var image = Image.new()
	var error = image.load(path)

	if error != OK:
		print("Failed to load image: ", path)
		return
	# Create a texture from the image
	var texture = ImageTexture.create_from_image(image)
	# Assign to Background sprite
	$Background.texture = texture
	print("Created sprite with texture size: ", texture.get_size())


func _on_load_map_button_pressed() -> void:
	# Create a file dialog
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png ; Image files"])

	# Add it temporarily to the scene
	add_child(dialog)

	# Connect its file_selected signal
	dialog.file_selected.connect(_on_file_dialog_file_selected)

	# Show the dialog
	dialog.popup_centered(Vector2(800, 600))


func _on_file_dialog_file_selected(path) -> void:
	load_map_image(path)
	print("Selected file: " + path)


func _input(event: InputEvent) -> void:
	# Get global transform
	var camera_transform = get_global_transform()

	if event is InputEventMouseButton:
		# Convert to local coordinates directly
		var map_pos = get_local_mouse_position()

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_click(map_pos)
			else:
				_handle_left_release(map_pos)

	elif event is InputEventMouseMotion:
		var map_pos = get_local_mouse_position()
		_handle_mouse_move(map_pos)


func _handle_left_click(position: Vector2) -> void:
	print("Click at: ", position)  # Debug print

	match current_tool:
		Tools.SELECT:
			_select_room_at_position(position)

		Tools.RECTANGLE, Tools.CIRCLE:
			drawing = true
			start_position = position

			# Create drawing helper
			if drawing_helper != null:
				drawing_helper.queue_free()

			drawing_helper = DrawingHelper.new()
			drawing_helper.shape_type = "rectangle" if current_tool == Tools.RECTANGLE else "circle"
			drawing_helper.start_pos = position
			drawing_helper.current_pos = position
			$Rooms.add_child(drawing_helper)

		Tools.POLYGON:
			if not drawing_polygon:
				drawing_polygon = true
				polygon_points = [position]

				# Create or reset drawing helper
				if drawing_helper == null:
					drawing_helper = DrawingHelper.new()
					$Rooms.add_child(drawing_helper)

				drawing_helper.shape_type = "polygon"
				drawing_helper.points = polygon_points
			else:
				# Check if near starting point to close the polygon
				if polygon_points.size() > 2 and position.distance_to(polygon_points[0]) < 20:
					_finalize_polygon()
				else:
					polygon_points.append(position)
					drawing_helper.points = polygon_points
					drawing_helper.queue_redraw()


func _handle_mouse_move(position: Vector2) -> void:
	if drawing_helper == null:
		return

	if drawing and (current_tool == Tools.RECTANGLE or current_tool == Tools.CIRCLE):
		drawing_helper.current_pos = position
		drawing_helper.queue_redraw()
	elif drawing_polygon and current_tool == Tools.POLYGON:
		drawing_helper.current_pos = position
		drawing_helper.queue_redraw()


func _handle_left_release(position: Vector2) -> void:
	if drawing and (current_tool == Tools.RECTANGLE or current_tool == Tools.CIRCLE):
		var size = position - start_position

		# Special handling for circles to make them consistent
		if current_tool == Tools.CIRCLE:
			# Calculate radius and center as we do when drawing
			var radius = size.length() / 2
			var center = (start_position + position) / 2

			# Adjust position and size to make a proper circle
			var pos = center - Vector2(radius, radius)
			size = Vector2(radius * 2, radius * 2)

			# Create the room
			var new_room = Room.new(next_room_id, "circle", pos, size)
			next_room_id += 1

			# Add to scene
			$Rooms.add_child(new_room)
			new_room.position = pos
			rooms.append(new_room)
		else:
			# Rectangle handling (stays the same)
			var pos = start_position
			if size.x < 0:
				pos.x += size.x
				size.x = -size.x
			if size.y < 0:
				pos.y += size.y
				size.y = -size.y

			# Create the room
			var new_room = Room.new(next_room_id, "rectangle", pos, size)
			next_room_id += 1

			# Add to the scene
			$Rooms.add_child(new_room)
			new_room.position = pos
			rooms.append(new_room)

		# Cleanup
		if drawing_helper != null:
			drawing_helper.queue_free()
			drawing_helper = null
		drawing = false


func screen_to_viewport_coordinates(screen_pos: Vector2) -> Vector2:
	# Get the viewport display's global transform
	var viewport_rect = $UI/ViewportDisplay.get_global_rect()

	# Get the viewport's size
	var viewport_size = $MapViewport.size

	# Calculate the scaling factor between display and actual viewport
	var scale_x = viewport_size.x / viewport_rect.size.x
	var scale_y = viewport_size.y / viewport_rect.size.y

	# Calculate the position relative to ViewportDisplay's top-left corner
	var local_pos = screen_pos - viewport_rect.position

	# Scale the position to match the actual viewport size
	var viewport_pos = Vector2(local_pos.x * scale_x, local_pos.y * scale_y)

	print("Screen pos: ", screen_pos, " -> Viewport pos: ", viewport_pos)
	return viewport_pos


func _update_temp_shape(position: Vector2) -> void:
	if temp_shape == null:
		return

	temp_shape.queue_redraw()
	#temp_shape.update()  # Force immediate redraw

	# Draw preview of shape
	var size = position - start_position
	temp_shape.draw_set_transform(start_position, 0, Vector2.ONE)

	if current_tool == Tools.RECTANGLE:
		temp_shape.draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.2, 0.9, 0.3), true)
		temp_shape.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.8), false, 2.0)
	elif current_tool == Tools.CIRCLE:
		var radius = min(abs(size.x), abs(size.y)) / 2
		var center = size / 2
		temp_shape.draw_circle(center, radius, Color(0.2, 0.2, 0.9, 0.3))
		temp_shape.draw_arc(center, radius, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)


func _update_temp_polygon(current_pos = null) -> void:
	if temp_polygon == null or polygon_points.size() < 2:
		return

	# Ensure we're using the correct node
	temp_polygon.queue_redraw()

	# Create a copy of points for drawing
	var draw_points = polygon_points.duplicate()
	if current_pos != null:
		draw_points.append(current_pos)

	# Draw lines between points
	for i in range(draw_points.size()):
		var start = draw_points[i]
		var end = draw_points[(i + 1) % draw_points.size()]
		temp_polygon.draw_line(start, end, Color(1, 1, 1, 0.8), 2.0)

	# Draw point markers
	for point in draw_points:
		temp_polygon.draw_circle(point, 5, Color(1, 1, 1, 0.8))


func _finalize_polygon() -> void:
	if polygon_points.size() < 3:
		return

	# Debug print to see actual polygon points
	print("Finalizing polygon with points: ", polygon_points)

	# Calculate bounding rect
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for point in polygon_points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)

	var pos = Vector2(min_x, min_y)
	var size = Vector2(max_x - min_x, max_y - min_y)

	# Create relative points
	var relative_points = []
	for point in polygon_points:
		relative_points.append(point - pos)

	# Create the room
	var new_room = Room.new(next_room_id, "polygon", pos, size)
	next_room_id += 1
	new_room.points = relative_points

	# Add to the scene - DIRECTLY at calculated position
	$Rooms.add_child(new_room)

	# IMPORTANT: Use the actual calculated position
	new_room.position = pos
	rooms.append(new_room)

	# Cleanup
	drawing_polygon = false
	polygon_points.clear()
	if drawing_helper != null:
		drawing_helper.queue_free()
		drawing_helper = null


func _select_room_at_position(position: Vector2) -> void:
	# Deselect all rooms first
	for room in rooms:
		room.set_selected(false)

	# Find and select the room at position
	for room in rooms:
		var local_pos = position - room.position
		if room.contains_point(local_pos):
			room.set_selected(true)
			print("Selected room ID: ", room.id)
			break
