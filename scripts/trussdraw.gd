extends Node2D

class TrussMember extends RefCounted:
	var start: Vector2
	var end: Vector2
	func _init(p1: Vector2, p2: Vector2):
		start = p1
		end = p2
	func has_point(p: Vector2):
		return (start == p) or (end == p)
	func matches(p1: Vector2, p2: Vector2):
		return (start == p1 and end == p2) or (start == p2 and end == p1)

enum Mode { DRAW_MEMBERS, ADD_SUPPORTS, ADD_FORCES, SOLVED}
var current_mode: = Mode.DRAW_MEMBERS

enum SupportType {NONE, PIN_X, PIN_X_NEG, PIN_Y, PIN_Y_NEG, ROLLER_X, ROLLER_X_NEG, ROLLER_Y, ROLLER_Y_NEG}
var node_supports = {}
var node_loads = {}
var member_forces = {}
var reaction_forces = {}

var force_start_nodes: Vector2
var is_drawing_forces:= false

var start_point: Vector2
var end_point: Vector2
var grabbed_point: Vector2
var original_point: Vector2
var is_drawing: = false
var is_grabbing: = false
var line_data: Array[TrussMember] = []

@export var line_width: float = 20.0
@export var line_thickness: float = 5.0
@export var line_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var snap_radius: float = 25.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			current_mode = Mode.DRAW_MEMBERS
		if event.keycode == KEY_S:
			current_mode = Mode.ADD_SUPPORTS
		if event.keycode == KEY_F:
			current_mode = Mode.ADD_FORCES
		if event.keycode == KEY_ENTER:
			pass
			
	match current_mode:
		Mode.DRAW_MEMBERS:
			handle_member_drawing(event)
		Mode.ADD_SUPPORTS:
			handle_support_logic(event)
		Mode.ADD_FORCES:
			handle_force_logic(event)
		Mode.SOLVED:
			pass

func draw_truss(p1: Vector2, p2: Vector2):
	var total_width = line_thickness + line_width
	var border_radius = total_width/2
	var truss_radius = line_width/2
	draw_line(p1, p2, border_color,total_width)
	draw_circle(p1,border_radius, border_color)
	draw_circle(p2,border_radius, border_color)
	draw_line(p1, p2, line_color,line_width)
	draw_circle(p1,truss_radius, line_color)
	draw_circle(p2,truss_radius, line_color)
	draw_circle(p1,4, border_color)
	draw_circle(p2,4, border_color)
	
func draw_force(from: Vector2, to: Vector2, force_color: Color):
	if from.distance_to(to) < 5:
		return
	draw_line(from,to,Color.RED,3.0)
	var dir = (to-from).normalized()
	var side = dir.rotated(PI/2)*10
	draw_primitive([to, to -dir*15 + side, to -dir*15-side],[force_color],[])
	
func apply_shift_lock(origin: Vector2, target: Vector2) -> Vector2:
	var diff_x = abs(target.x - origin.x)
	var diff_y = abs(target.y - origin.y)
	if diff_x > diff_y:
		return Vector2(target.x, origin.y)
	else:
		return Vector2(origin.x, target.y)

func best_pos(p: Vector2) -> Vector2:
	for member in line_data:
		if p.distance_to(member.start) < snap_radius:
			return member.start
		if p.distance_to(member.end) < snap_radius:
			return member.end
	return p

func not_exists(p1: Vector2, p2: Vector2):
	for member in line_data:
		if member.matches(p1  ,p2):
			return false
	return true
	

func update_grabbed_point(new_pos: Vector2):
	for member in  line_data:
		if member.start == grabbed_point:
			member.start = new_pos
		if member.end == grabbed_point:
			member.end = new_pos
	grabbed_point = new_pos
	
func get_unique_nodes():
	var points = []
	for m in line_data:
		if not points.has(m.start):
			points.append(m.start)
		if not points.has(m.end):
			points.append(m.end)
	return points

func _draw() -> void:
	for member in line_data:
		draw_truss(member.start,member.end)
		
	for node in node_loads:
		var vec = node_loads[node]
		draw_force(node - vec, node, Color.RED)
		
	if is_drawing:
		var mouse_pos = best_pos(get_viewport().get_mouse_position())
		if Input.is_key_pressed(KEY_SHIFT):
			mouse_pos = apply_shift_lock(start_point, mouse_pos)
		draw_truss(start_point, mouse_pos)
		
	if is_drawing_forces:
		var preview_mouse = best_pos(get_viewport().get_mouse_position())
		if Input.is_key_pressed(KEY_SHIFT):
			preview_mouse = apply_shift_lock(force_start_nodes, preview_mouse)
			preview_mouse = best_pos(preview_mouse)
		if Input.is_key_pressed(KEY_ALT):
			draw_force(preview_mouse, force_start_nodes, Color.ORANGE)
		else:
			draw_force(force_start_nodes, preview_mouse, Color.ORANGE)
	
	for node_pos in node_supports:
		var type = node_supports[node_pos]
		draw_support_icon(node_pos, type)

func handle_member_drawing(event):
	if event is InputEventMouseButton and event.pressed:
		if is_grabbing:
			if event.button_index == MOUSE_BUTTON_LEFT:
				update_grabbed_point(best_pos(event.position))
				line_data = line_data.filter(func(line): return line.start != line.end)
				is_grabbing = false
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				update_grabbed_point(original_point)
				is_grabbing = false
				get_viewport().set_input_as_handled()
				return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_drawing:
				start_point = best_pos(event.position)
				is_drawing = true
			else:
				end_point = best_pos(event.position)
				if event.shift_pressed:
					end_point = apply_shift_lock(start_point, end_point)
					end_point = best_pos(end_point)
				
				if ((end_point - start_point).length() > 0.1) and not_exists(start_point, end_point):
					line_data.append(TrussMember.new(start_point, end_point))
				is_drawing = false
				queue_redraw()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_drawing:
				is_drawing = false
			else:
				line_data = line_data.filter(func(member):
					return !member.has_point(best_pos(event.position))
				)
			queue_redraw()

	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		var mouse_pos = get_viewport().get_mouse_position()
		var snapped_pos = best_pos(mouse_pos)
		if mouse_pos.distance_to(snapped_pos) < snap_radius:
			is_drawing = false
			is_grabbing = true
			grabbed_point = snapped_pos
			original_point = snapped_pos

	if is_grabbing and event is InputEventMouseMotion:
		var raw_mouse = event.position
		var snap_pos = raw_mouse
		for member in line_data:
			if member.start != grabbed_point and raw_mouse.distance_to(member.start) < snap_radius:
				snap_pos = member.start
				break
			if member.end != grabbed_point and raw_mouse.distance_to(member.end) < snap_radius:
				snap_pos = member.end
				break
		update_grabbed_point(snap_pos)
		queue_redraw()

func handle_support_logic(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = best_pos(event.position)
		if event.position.distance_to(pos) < snap_radius:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var current = node_supports.get(pos, SupportType.NONE)
				node_supports[pos] = (current + 1) % 9
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				node_supports.erase(pos)
		queue_redraw()
		
func handle_force_logic(event):
	if event is InputEventMouseButton:
		var snapped_node = best_pos(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				force_start_nodes = snapped_node
				is_drawing_forces = true
			else:
				if is_drawing_forces:
					var target_pos = best_pos(event.position)
					if Input.is_key_pressed(KEY_SHIFT):
						target_pos = apply_shift_lock(force_start_nodes, target_pos)
						target_pos = best_pos(target_pos)
					var force_vec: Vector2
					if Input.is_key_pressed(KEY_ALT):
						force_vec = force_start_nodes - target_pos
					else:
						force_vec = target_pos - force_start_nodes
					if force_vec.length() > 5:
						node_loads[force_start_nodes] = force_vec
					is_drawing_forces = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if event.position.distance_to(snapped_node) < snap_radius:
				node_loads.erase(snapped_node)
	queue_redraw()
	
func draw_support_icon(pos: Vector2, type: SupportType):
	var size = 15.0
	var color = Color.GREEN
	match type:
		SupportType.PIN_X:
			draw_support_triangle(pos, Vector2(0, size*1.5),color)
		SupportType.PIN_X_NEG:
			draw_support_triangle(pos,Vector2(0,-size*1.5), color)
		SupportType.PIN_Y:
			draw_support_triangle(pos, Vector2(size*1.5,0), color)
		SupportType.PIN_Y_NEG:
			draw_support_triangle(pos, Vector2(-size*1.5,0), color)
		SupportType.ROLLER_X:
			draw_support_triangle(pos, Vector2(0,size), color)
			draw_circle(pos + Vector2(-size/2 ,size +5),4, color)
			draw_circle(pos + Vector2(size/2 ,size +5),4, color)
		SupportType.ROLLER_X_NEG:
			draw_support_triangle(pos, Vector2(0,-size), color)
			draw_circle(pos + Vector2(-size/2 ,-size -5),4, color)
			draw_circle(pos + Vector2(size/2 ,-size -5),4, color)
		SupportType.ROLLER_Y:
			draw_support_triangle(pos, Vector2(size,0), color)
			draw_circle(pos + Vector2(size +5, -size/2),4, color)
			draw_circle(pos + Vector2(size +5, size/2),4, color)
		SupportType.ROLLER_Y_NEG:
			draw_support_triangle(pos, Vector2(-size,0), color)
			draw_circle(pos + Vector2(-size -5, -size/2),4, color)
			draw_circle(pos + Vector2(-size -5, size/2),4, color)
			

func draw_support_triangle(center: Vector2, offset: Vector2, color: Color):
	var side = offset.rotated(PI/2).normalized() * 15.0
	var p1 = center
	var p2 = center + offset - side
	var p3 = center + offset + side
	draw_colored_polygon([p1,p2,p3], color)

func _process(_delta: float) -> void:
	queue_redraw()
	
func solve_system(A: Array, B: Array):
	var n = A.size()
	var M = []
	
	for i in A:
		if i.size() != n:
			print("Not Square!")
			return null
	
	if n != B.size():
		print("Size Mismatch")
		return null
	
	for i in range(n):
		var row = A[i].duplicate()
		row.append(B[i])
		M.append(row)

	for i in range(n):
		var max_row = i
		for k in range(i + 1, n):
			if abs(M[k][i]) > abs(M[max_row][i]):
				max_row = k
		
		var temp = M[i]
		M[i] = M[max_row]
		M[max_row] = temp

		if abs(M[i][i]) < 1e-10:
			return null

		for k in range(i + 1, n):
			var factor = float(M[k][i]) / float(M[i][i])
			for j in range(i, n + 1):
				M[k][j] -= factor * M[i][j]

	var x = []
	x.resize(n)
	for i in range(n - 1, -1, -1):
		var sum = 0.0
		for j in range(i + 1, n):
			sum += M[i][j] * x[j]
		x[i] = (M[i][n] - sum) / M[i][i]
	
	return x
