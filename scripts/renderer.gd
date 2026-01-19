extends Node2D

var main: Node2D 

func _draw() -> void:
	if not main or not main.config:
		return
	
	for member in main.line_data:
		var m_color = main.config.line_color
		if main.current_mode == main.Mode.SOLVED and main.member_forces.has(member):
			var force = main.member_forces[member]
			if force > 0.1: 
				m_color = Color.CYAN
			elif force < -0.1: 
				m_color = Color.TOMATO
			else: 
				m_color = Color.DARK_GRAY
		main.draw_truss(member.start, member.end, m_color)

	for node in main.node_loads:
		var vec = main.node_loads[node]
		main.draw_force(node - vec, node, Color.RED)

	if main.is_drawing:
		var mouse_pos = main.get_snapped_mouse()
		if Input.is_key_pressed(KEY_SHIFT):
			mouse_pos = main.apply_shift_lock(main.start_point, mouse_pos)
		main.draw_truss(main.start_point, mouse_pos, Color.GRAY)

	if main.is_drawing_forces:
		var preview_mouse = main.get_snapped_mouse()
		if Input.is_key_pressed(KEY_SHIFT):
			preview_mouse = main.best_pos(main.apply_shift_lock(main.force_start_nodes, preview_mouse))
		if Input.is_key_pressed(KEY_ALT):
			main.draw_force(preview_mouse, main.force_start_nodes, Color.ORANGE)
		else:
			main.draw_force(main.force_start_nodes, preview_mouse, Color.ORANGE)

	for node_pos in main.node_supports:
		main.draw_support_icon(node_pos, main.node_supports[node_pos])
