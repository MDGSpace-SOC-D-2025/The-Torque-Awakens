class_name ObjectManager

var main: Node2D
var is_drawing := false
var is_grabbing := false
var is_rotating := false
var box_start := Vector2.ZERO
var circle_center := Vector2.ZERO
var selected_object = null
var rotation_start_angle := 0.0
var original_pos := Vector2.ZERO

func setup(m: Node2D):
	main = m

func clear_selection():
	is_drawing = false
	is_grabbing = false
	is_rotating = false
	selected_object = null

func handle_box_input(event: InputEvent):
	var mouse_pos = main.get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_drawing:
				is_drawing = true
				box_start = mouse_pos
			else:
				var size = (mouse_pos - box_start).abs()
				if size.length() > 5:
					_create_box(box_start, size)
				is_drawing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_drawing: is_drawing = false

func handle_circle_input(event: InputEvent):
	var mouse_pos = main.get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_drawing:
				is_drawing = true
				circle_center = mouse_pos
			else:
				var radius = circle_center.distance_to(mouse_pos)
				if radius > 5:
					_create_circle(circle_center, radius)
				is_drawing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_drawing: is_drawing = false

func handle_object_edit(event: InputEvent):
	var mouse_pos = main.get_global_mouse_position()
	if event is InputEventKey and event.pressed and selected_object:
		if event.keycode == KEY_M:
			print("Current mass: ", selected_object.mass, " kg")
		elif event.keycode == KEY_G:
			is_grabbing = true
			original_pos = selected_object.position
		elif event.keycode == KEY_R:
			is_rotating = true
			rotation_start_angle = selected_object.rotation
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_grabbing: is_grabbing = false
			elif is_rotating: is_rotating = false
			else: selected_object = _get_object_at(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_grabbing:
				selected_object.position = original_pos
				is_grabbing = false
			elif is_rotating:
				selected_object.rotation = rotation_start_angle
				is_rotating = false
			else: _remove_object_at(mouse_pos)
	
	if event is InputEventMouseMotion:
		if is_grabbing and selected_object:
			selected_object.position = mouse_pos
			if not is_rotating: _auto_snap_rotation(selected_object)
		elif is_rotating and selected_object:
			var angle = (mouse_pos - selected_object.position).angle()
			selected_object.rotation = angle

func _create_box(corner: Vector2, size: Vector2):
	var obj = RigidObject.new()
	obj.is_box = true
	obj.position = corner + size / 2
	obj.size = size
	obj.mass = main.default_mass
	obj.rotation = 0.0
	var body = Node2D.new()
	body.position = obj.position
	body.rotation = obj.rotation
	main.object_container.add_child(body)
	obj.body = body
	main.objects.append(obj)
	main.request_mass_input(obj)

func _create_circle(center: Vector2, radius: float):
	var obj = RigidObject.new()
	obj.is_box = false
	obj.position = center
	obj.size = Vector2(radius, radius)
	obj.mass = main.default_mass
	obj.rotation = 0.0
	var body = Node2D.new()
	body.position = obj.position
	main.object_container.add_child(body)
	obj.body = body
	main.objects.append(obj)
	main.request_mass_input(obj)

func _remove_object_instance(obj: RigidObject):
	if obj in main.objects:
		main.objects.erase(obj)
		if is_instance_valid(obj.body):
			obj.body.queue_free()

func _auto_snap_rotation(obj: RigidObject):
	if not obj.is_box: return
	var closest_wall = null
	var min_dist = INF
	for wall in main.walls:
		var dist = _dist_to_segment(obj.position, wall.start, wall.end)
		if dist < min_dist:
			min_dist = dist
			closest_wall = wall
	if closest_wall and min_dist < main.snap_distance:
		var wall_angle = (closest_wall.end - closest_wall.start).angle()
		obj.rotation = wall_angle

func _get_object_at(pos: Vector2):
	for obj in main.objects:
		var check_dist = obj.size.x if not obj.is_box else obj.size.length() / 2
		if obj.position.distance_to(pos) < check_dist: return obj
	return null

func _remove_object_at(pos: Vector2):
	var target = _get_object_at(pos)
	if target: _remove_object_instance(target)

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = a.distance_to(b)
	if ab == 0: return p.distance_to(a)
	var t = max(0, min(1, (p - a).dot(b - a) / (ab * ab)))
	var projection = a + t * (b - a)
	return p.distance_to(projection)

func draw_objects(t_scale: float):
	for obj in main.objects:
		var color = main.color_box if obj.is_box else main.color_circle
		if obj == selected_object: color = main.color_selected
		if obj.is_box:
			var half = obj.size / 2
			var corners = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
			var rotated = []
			for c in corners: rotated.append(obj.position + c.rotated(obj.rotation))
			for i in range(4): main.draw_line(rotated[i], rotated[(i + 1) % 4], color, 2.0 * t_scale)
			main.draw_circle(obj.position, 3 * t_scale, color)
		else:
			main.draw_arc(obj.position, obj.size.x, 0, TAU, 32, color, 2.0 * t_scale)
			main.draw_circle(obj.position, 3 * t_scale, color)
		for force in obj.forces:
			var force_end = obj.position + force.direction * force.magnitude
			main.draw_line(obj.position, force_end, main.color_force, 2.0 * t_scale)
			_draw_arrow_head(force_end, force.direction, main.color_force, t_scale)
		for contact in obj.contacts:
			main.draw_line(contact.point, obj.position, main.color_contact_normal, 1.5 * t_scale)
			main.draw_circle(contact.point, 3 * t_scale, main.color_contact_normal)
	if is_drawing and main.current_mode == 1:
		var mouse_pos = main.get_global_mouse_position()
		var size = (mouse_pos - box_start).abs()
		var corners = [box_start, box_start + Vector2(size.x, 0), box_start + size, box_start + Vector2(0, size.y)]
		for i in range(4): main.draw_line(corners[i], corners[(i + 1) % 4], main.color_preview_smooth, 2.0 * t_scale)
	if is_drawing and main.current_mode == 2:
		var mouse_pos = main.get_global_mouse_position()
		var radius = circle_center.distance_to(mouse_pos)
		main.draw_arc(circle_center, radius, 0, TAU, 32, main.color_preview_smooth, 2.0 * t_scale)

func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color, t_scale: float):
	var size = 8.0 * t_scale
	var angle = 0.5
	var left = tip - direction.rotated(angle) * size
	var right = tip - direction.rotated(-angle) * size
	main.draw_line(tip, left, color, 2.0 * t_scale)
	main.draw_line(tip, right, color, 2.0 * t_scale)
