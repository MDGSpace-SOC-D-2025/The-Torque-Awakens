extends Node
class_name TrussInputManager

var host 

func handle_member_drawing(event):
	if event is InputEventMouseButton and event.pressed:
		if host.is_grabbing:
			if event.button_index == MOUSE_BUTTON_LEFT:
				host.update_grabbed_point(host.best_pos(event.position))
				host.line_data = host.line_data.filter(func(line): return line.start != line.end)
				host.is_grabbing = false
				host.get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				host.update_grabbed_point(host.original_point)
				host.is_grabbing = false
				host.get_viewport().set_input_as_handled()
				return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if not host.is_drawing:
				host.start_point = host.best_pos(event.position)
				host.is_drawing = true
			else:
				host.end_point = host.best_pos(event.position)
				if event.shift_pressed:
					host.end_point = host.apply_shift_lock(host.start_point, host.end_point)
					host.end_point = host.best_pos(host.end_point)
				
				if ((host.end_point - host.start_point).length() > 0.1) and host.not_exists(host.start_point, host.end_point):
					host.line_data.append(TrussMember.new(host.start_point, host.end_point))
				host.is_drawing = false
				host.renderer.queue_redraw()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if host.is_drawing:
				host.is_drawing = false
			else:
				host.line_data = host.line_data.filter(func(member):
					return !member.has_point(host.best_pos(event.position))
				)
			host.renderer.queue_redraw()

	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		var mouse_pos = host.get_viewport().get_mouse_position()
		var snapped_pos = host.best_pos(mouse_pos)
		if mouse_pos.distance_to(snapped_pos) < host.config.snap_radius:
			host.is_drawing = false
			host.is_grabbing = true
			host.grabbed_point = snapped_pos
			host.original_point = snapped_pos

	if host.is_grabbing and event is InputEventMouseMotion:
		var raw_mouse = event.position
		var snap_pos = raw_mouse
		for member in host.line_data:
			if member.start != host.grabbed_point and raw_mouse.distance_to(member.start) < host.config.snap_radius:
				snap_pos = member.start
				break
			if member.end != host.grabbed_point and raw_mouse.distance_to(member.end) < host.config.snap_radius:
				snap_pos = member.end
				break
		host.update_grabbed_point(snap_pos)
		host.renderer.queue_redraw()

func handle_support_logic(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = host.best_pos(event.position)
		if event.position.distance_to(pos) < host.config.snap_radius:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var current = host.node_supports.get(pos, 0) # SupportType.NONE
				host.node_supports[pos] = (current + 1) % 9
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				host.node_supports.erase(pos)
		host.renderer.queue_redraw()

func handle_force_logic(event):
	if event is InputEventMouseButton:
		var snapped_node = host.best_pos(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				host.force_start_nodes = snapped_node
				host.is_drawing_forces = true
			else:
				if host.is_drawing_forces:
					var target_pos = host.best_pos(event.position)
					if Input.is_key_pressed(KEY_SHIFT):
						target_pos = host.apply_shift_lock(host.force_start_nodes, target_pos)
						target_pos = host.best_pos(target_pos)
					var force_vec: Vector2
					if Input.is_key_pressed(KEY_ALT):
						force_vec = host.force_start_nodes - target_pos
					else:
						force_vec = target_pos - host.force_start_nodes
					if force_vec.length() > 5:
						host.node_loads[host.force_start_nodes] = force_vec
					host.is_drawing_forces = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if event.position.distance_to(snapped_node) < host.config.snap_radius:
				host.node_loads.erase(snapped_node)
	host.renderer.queue_redraw()
