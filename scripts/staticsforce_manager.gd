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
				var force_vec = mouse_pos - force_start
				if Input.is_key_pressed(KEY_ALT):
					force_vec = -force_vec
				if force_vec.length() > 5:
					var force = ForceData.new()
					force.direction = force_vec.normalized()
					force.magnitude = force_vec.length()
					selected_object.forces.append(force)
				is_drawing = false
				selected_object = null
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_drawing:
				is_drawing = false
				selected_object = null
			else:
				remove_force_at(mouse_pos)

func remove_force_at(pos: Vector2):
	for obj in main.objects:
		for i in range(obj.forces.size() - 1, -1, -1):
			var force = obj.forces[i]
			var force_end = obj.position + force.direction * force.magnitude
			var dist = _dist_to_segment(pos, obj.position, force_end)
			if dist < 10.0:
				obj.forces.remove_at(i)
				return

func _get_object_at(pos: Vector2):
	for obj in main.objects:
		var check_dist = obj.size.x if not obj.is_box else obj.size.length() / 2
		if obj.position.distance_to(pos) < check_dist:
			return obj
	return null

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = a.distance_to(b)
	if ab == 0: return p.distance_to(a)
	var t = max(0, min(1, (p - a).dot(b - a) / (ab * ab)))
	var projection = a + t * (b - a)
	return p.distance_to(projection)

func draw_force_preview():
	if is_drawing and selected_object:
		var mouse_pos = main.get_global_mouse_position()
		var force_vec = mouse_pos - force_start
		if Input.is_key_pressed(KEY_ALT):
			force_vec = -force_vec
		var force_end = force_start + force_vec
		main.draw_line(force_start, force_end, main.color_preview_smooth, 2.0)
		_draw_arrow_head(force_end, force_vec.normalized(), main.color_preview_smooth)

func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color):
	var size = 8.0
	var angle = 0.5
	var left = tip - direction.rotated(angle) * size
	var right = tip - direction.rotated(-angle) * size
	main.draw_line(tip, left, color, 2.0)
	main.draw_line(tip, right, color, 2.0)
