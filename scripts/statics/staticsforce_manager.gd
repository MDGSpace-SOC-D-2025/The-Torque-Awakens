class_name ForceManager

var main: Node2D
var is_drawing := false
var selected_object = null
var force_start := Vector2.ZERO

func setup(m: Node2D):
	main = m

func handle_input(event: InputEvent):
	var mouse_pos = main.get_global_mouse_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_drawing:
				var obj = _get_object_at(mouse_pos)
				if obj:
					selected_object = obj
					is_drawing = true
					force_start = obj.position
			else:
				var force_vec = _get_processed_vec(mouse_pos)
				if force_vec.length() > 2:
					main.request_force_magnitude(selected_object, force_vec.normalized(), force_vec.length())
				is_drawing = false
				selected_object = null
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_drawing:
				is_drawing = false
				selected_object = null
			else:
				remove_force_at(mouse_pos)

func _get_processed_vec(mouse_pos: Vector2) -> Vector2:
	var vec = mouse_pos - force_start
	
	if Input.is_key_pressed(KEY_SHIFT):
		if abs(vec.x) > abs(vec.y):
			vec.y = 0
		else:
			vec.x = 0
			
	if Input.is_key_pressed(KEY_ALT):
		vec = -vec
		
	return vec

func remove_force_at(pos: Vector2):
	for obj in main.objects:
		for i in range(obj.forces.size() - 1, -1, -1):
			var force = obj.forces[i]
			var force_end = obj.position + force.direction * force.magnitude
			if _dist_to_segment(pos, obj.position, force_end) < 10.0:
				obj.forces.remove_at(i)
				return

func _get_object_at(pos: Vector2):
	for obj in main.objects:
		var check_dist = obj.size.x if not obj.is_box else obj.size.length() / 2
		if obj.position.distance_to(pos) < check_dist: return obj
	return null

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = a.distance_to(b)
	if ab == 0: return p.distance_to(a)
	var t = max(0, min(1, (p - a).dot(b - a) / (ab * ab)))
	return p.distance_to(a + t * (b - a))

func draw_force_preview(t_scale: float):
	if is_drawing and selected_object:
		var force_vec = _get_processed_vec(main.get_global_mouse_position())
		var force_end = force_start + force_vec
		main.draw_line(force_start, force_end, main.color_preview_smooth, 2.0 * t_scale)
		_draw_arrow_head(force_end, force_vec.normalized(), main.color_preview_smooth, t_scale)

func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color, t_scale: float):
	if direction == Vector2.ZERO: return
	var size = 8.0 * t_scale
	var left = tip - direction.rotated(0.5) * size
	var right = tip - direction.rotated(-0.5) * size
	main.draw_line(tip, left, color, 2.0 * t_scale)
	main.draw_line(tip, right, color, 2.0 * t_scale)
