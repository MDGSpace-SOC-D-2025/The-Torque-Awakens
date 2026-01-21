class_name WallManager

var main: Node2D
var is_drawing := false
var is_grabbing := false
var wall_start := Vector2.ZERO
var wall_end := Vector2.ZERO
var grabbed_joint := Vector2.ZERO
var original_joint_pos := Vector2.ZERO

func setup(m: Node2D):
	main = m

func handle_input(event: InputEvent):
	var mouse_pos = main.get_global_mouse_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_drawing:
				is_drawing = true
				wall_start = _snap_to_joints(mouse_pos)
				wall_end = wall_start
			else:
				if wall_start.distance_to(wall_end) > 5:
					_create_wall(wall_start, wall_end)
				is_drawing = false
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_drawing:
				is_drawing = false
			elif is_grabbing:
				_update_grabbed_joint(original_joint_pos)
				is_grabbing = false
			else:
				_remove_wall_at(mouse_pos)
	
	if event is InputEventMouseMotion:
		if is_drawing:
			wall_end = _snap_to_joints(mouse_pos)
			if Input.is_key_pressed(KEY_SHIFT):
				var diff = wall_end - wall_start
				if abs(diff.x) > abs(diff.y):
					wall_end.y = wall_start.y
				else:
					wall_end.x = wall_start.x
		elif is_grabbing:
			_update_grabbed_joint(mouse_pos)

func _snap_to_joints(pos: Vector2) -> Vector2:
	for w in main.walls:
		if pos.distance_to(w.start) < main.snap_distance:
			return w.start
		if pos.distance_to(w.end) < main.snap_distance:
			return w.end
	return pos

func _create_wall(p1: Vector2, p2: Vector2):
	var new_wall = WallData.new()
	new_wall.start = p1
	new_wall.end = p2
	new_wall.type = 0
	
	var body = StaticBody2D.new()
	var col = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	
	shape.a = p1
	shape.b = p2
	col.shape = shape
	body.add_child(col)
	
	main.wall_container.add_child(body)
	new_wall.body = body
	main.walls.append(new_wall)

func _update_grabbed_joint(new_pos: Vector2):
	var target_pos = new_pos
	
	if Input.is_key_pressed(KEY_SHIFT):
		var reference_point = Vector2.INF
		for w in main.walls:
			if w.start == grabbed_joint:
				reference_point = w.end
				break
			elif w.end == grabbed_joint:
				reference_point = w.start
				break
		
		if reference_point != Vector2.INF:
			var diff = target_pos - reference_point
			if abs(diff.x) > abs(diff.y):
				target_pos.y = reference_point.y
			else:
				target_pos.x = reference_point.x
	
	for w in main.walls:
		if w.start == grabbed_joint:
			w.start = target_pos
		if w.end == grabbed_joint:
			w.end = target_pos
	
	grabbed_joint = target_pos

func _remove_wall_at(pos: Vector2):
	var to_remove = -1
	for i in range(main.walls.size()):
		var w = main.walls[i]
		var dist = _dist_to_segment(pos, w.start, w.end)
		if dist < 10.0:
			to_remove = i
			break
	
	if to_remove != -1:
		main.walls[to_remove].body.queue_free()
		main.walls.remove_at(to_remove)

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = a.distance_to(b)
	if ab == 0: return p.distance_to(a)
	var t = max(0, min(1, (p - a).dot(b - a) / (ab * ab)))
	var projection = a + t * (b - a)
	return p.distance_to(projection)

func draw_walls():
	for w in main.walls:
		_draw_wall_style(w.start, w.end, main.color_smooth)
	
	if is_drawing:
		_draw_wall_style(wall_start, wall_end, main.color_preview_smooth)

func _draw_wall_style(p1: Vector2, p2: Vector2, color: Color):
	main.draw_line(p1, p2, color, main.wall_thickness)
	
	var dir = (p2 - p1).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var length = p1.distance_to(p2)
	
	for i in range(0, int(length), int(main.hatch_step)):
		var s = p1 + dir * i
		var hatch_end = s + (normal + dir) * main.hatch_length
		main.draw_line(s, hatch_end, color, 1.0)
